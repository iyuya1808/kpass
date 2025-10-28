const express = require('express');
const { body, validationResult } = require('express-validator');
const { loginToKLMS, launchManualLoginBrowser, waitForManualLogin, waitForExternalBrowserLogin } = require('../auth/puppeteer-auth');
const sessionManager = require('../auth/session-manager');
const { generateToken, verifyToken, createRateLimiter, sanitizeInput } = require('../utils/security');
const logger = require('../utils/logger');

const router = express.Router();

// Debug: trace auth router hits (temporary; safe)
router.use((req, res, next) => {
  try {
    const msg = `AuthRouter hit: ${req.method} ${req.originalUrl} path=${req.path}`;
    logger.info(msg);
    // Also print to stdout to ensure visibility regardless of logger config
    // eslint-disable-next-line no-console
    console.log(msg);
  } catch (_) {}
  next();
});

/**
 * GET /api/health
 * Health check endpoint
 */
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Proxy server is running',
    timestamp: new Date().toISOString()
  });
});

// Create rate limiter instance at module level (not in request handler)
const authWindowMs = parseInt(process.env.AUTH_RATE_LIMIT_WINDOW_MS || `${15 * 60 * 1000}`); // default 15min
const authMax = parseInt(process.env.AUTH_RATE_LIMIT_MAX || (process.env.NODE_ENV === 'production' ? '50' : '1000'));
const authRateLimit = createRateLimiter({
  windowMs: authWindowMs,
  max: authMax, // configurable (prod default 50)
  message: {
    success: false,
    error: 'Too many authentication attempts, please try again later.',
    retryAfter: Math.ceil(authWindowMs / 1000)
  },
  standardHeaders: true, // Return rate limit info in headers
  legacyHeaders: false,
  handler: (req, res) => {
    const retryAfter = Math.ceil(authWindowMs / 1000);
    res.status(429).json({
      success: false,
      error: 'Too Many Requests',
      message: 'Too many authentication attempts, please try again later.',
      retryAfter: retryAfter
    });
  }
});

// Apply rate limiting to auth routes
const applyAuthRateLimit = (req, res, next) => {
  return authRateLimit(req, res, next);
};

/**
 * POST /api/auth/start-external-browser-login
 * Start external browser login process
 */
router.post('/start-external-browser-login', applyAuthRateLimit, [
  body('username')
    .notEmpty()
    .withMessage('Username is required')
    .isLength({ min: 3, max: 50 })
    .withMessage('Username must be between 3 and 50 characters')
    .customSanitizer(sanitizeInput)
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { username } = req.body;
    const userId = `user_${username}`;

    logger.info('Starting external browser login for user: %s', username);

    // Generate a unique session ID
    const sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    // Store session data for external browser login
    const activeExternalLogins = req.app.locals.activeExternalLogins || new Map();
    activeExternalLogins.set(sessionId, {
      userId: userId,
      username: username,
      startTime: Date.now(),
      status: 'pending'
    });
    req.app.locals.activeExternalLogins = activeExternalLogins;

    // Create simple login URL for K-LMS
    const baseUrl = process.env.CANVAS_BASE_URL || 'https://lms.keio.jp';
    const loginUrl = `${baseUrl}/login`;

    logger.info('External browser login session created for user %s with session ID: %s', username, sessionId);

    res.json({
      success: true,
      message: 'External browser login session created',
      loginUrl: loginUrl,
      sessionId: sessionId,
      userId: userId
    });

  } catch (error) {
    logger.error('Failed to start external browser login: %s', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to start external browser login',
      message: error.message
    });
  }
});

/**
 * GET /api/auth/check-login-status/:sessionId
 * Check if user has completed login in external browser
 */
router.get('/check-login-status/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;

    logger.info('Checking login status for session: %s', sessionId);

    // Get session data
    const activeExternalLogins = req.app.locals.activeExternalLogins || new Map();
    const sessionData = activeExternalLogins.get(sessionId);

    if (!sessionData) {
      return res.status(404).json({
        success: false,
        error: 'Session not found',
        message: 'The session has expired or does not exist'
      });
    }

    const { userId, username } = sessionData;

    // Check if session has expired (10 minutes timeout)
    const sessionAge = Date.now() - sessionData.startTime;
    const maxAge = 10 * 60 * 1000; // 10 minutes

    if (sessionAge > maxAge) {
      activeExternalLogins.delete(sessionId);
      return res.status(408).json({
        success: false,
        error: 'Session expired',
        message: 'The login session has expired. Please try again.'
      });
    }

    // For external browser login, we don't need to launch a browser
    // The user logs in through their own browser, and we just check the session status
    // This is a simplified check that doesn't require launching a browser on the server
    
    logger.info('Checking external browser login status for session: %s', sessionId);
    
    // For now, we'll assume the user needs to complete login through their external browser
    // The actual login completion will be handled in the complete-external-browser-login endpoint
    res.json({
      success: true,
      loggedIn: false,
      message: 'Please complete login in your external browser, then call the complete endpoint'
    });

  } catch (error) {
    logger.error('Failed to check login status: %s', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to check login status',
      message: error.message
    });
  }
});

/**
 * POST /api/auth/complete-external-browser-login
 * Complete external browser login process with cookies from user's browser
 */
router.post('/complete-external-browser-login', applyAuthRateLimit, [
  body('sessionId')
    .notEmpty()
    .withMessage('Session ID is required')
    .customSanitizer(sanitizeInput),
  body('cookies')
    .notEmpty()
    .withMessage('Cookies are required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { sessionId, cookies } = req.body;

    logger.info('Completing external browser login for session: %s', sessionId);

    // Get session data
    const activeExternalLogins = req.app.locals.activeExternalLogins || new Map();
    const sessionData = activeExternalLogins.get(sessionId);

    if (!sessionData) {
      return res.status(404).json({
        success: false,
        error: 'Session not found',
        message: 'The session has expired or does not exist'
      });
    }

    const { userId, username } = sessionData;

    // Check if session has expired (5 minutes timeout)
    const sessionAge = Date.now() - sessionData.startTime;
    const maxAge = 5 * 60 * 1000; // 5 minutes

    if (sessionAge > maxAge) {
      activeExternalLogins.delete(sessionId);
      return res.status(408).json({
        success: false,
        error: 'Session expired',
        message: 'The login session has expired. Please try again.'
      });
    }

    // For external browser login, we'll launch a server-side browser to complete the login
    // This ensures the browser runs only on the proxy server
    try {
      logger.info(`Starting server-side browser login for session ${sessionId}`);
      
      const { browser, page } = await launchManualLoginBrowser(userId);
      
      // Navigate to K-LMS login page
      await page.goto(`${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}/login`, { 
        waitUntil: 'networkidle2',
        timeout: 15000 
      });

      const currentUrl = page.url();
      logger.info(`Current URL after navigation for session ${sessionId}: ${currentUrl}`);
      
      // Wait for user to complete login (this will wait for navigation away from login page)
      logger.info(`Waiting for user to complete login for session ${sessionId}`);
      
      // Wait for navigation away from login page (indicating successful login)
      await page.waitForFunction(() => {
        const url = window.location.href;
        // Wait until we're back to K-LMS domain and not on login/SAML pages
        return url.includes('lms.keio.jp') && 
               !url.includes('/login') && 
               !url.includes('/portal') &&
               !url.includes('okta.com') &&
               !url.includes('/saml') &&
               !url.includes('/auth');
      }, { timeout: 300000 }); // Wait up to 5 minutes for user to complete login
      
      logger.info(`Login completed for session ${sessionId}`);

      // Verify login was successful
      const finalUrl = page.url();
      logger.info(`Final URL after login for session ${sessionId}: ${finalUrl}`);
      
      // Check if we're still on login/SAML pages
      if (finalUrl.includes('/login') || 
          finalUrl.includes('/auth') || 
          finalUrl.includes('/portal') ||
          finalUrl.includes('okta.com') ||
          finalUrl.includes('/saml')) {
        await browser.close();
        throw new Error('Login was not successful - still on authentication pages');
      }

      // Get cookies from the logged-in session
      logger.info('Extracting cookies from logged-in session for session: %s', sessionId);
      const cookies = await page.cookies('https://lms.keio.jp');

      logger.info('Received %d cookies for session: %s', cookies ? cookies.length : 0, sessionId);
      
      // Log cookies for debugging
      if (Array.isArray(cookies) && cookies.length > 0) {
        logger.info(`All cookies found for session ${sessionId}:`);
        cookies.forEach((cookie, index) => {
          logger.info(`Cookie ${index + 1}: ${cookie.name}=${cookie.value.substring(0, 20)}... (domain: ${cookie.domain}, path: ${cookie.path}, secure: ${cookie.secure}, httpOnly: ${cookie.httpOnly})`);
        });
        
        // Check for session-related cookies
        const sessionCookies = cookies.filter(c => 
          c.name.includes('session') || 
          c.name.includes('canvas') || 
          c.name.includes('auth') ||
          c.name.includes('user') ||
          c.name.includes('login')
        );
        
        logger.info(`Session-related cookies found: ${sessionCookies.length}`);
        sessionCookies.forEach((cookie, index) => {
          logger.info(`Session Cookie ${index + 1}: ${cookie.name}=${cookie.value.substring(0, 20)}...`);
        });
      }

      if (cookies && cookies.length > 0) {
        // Convert cookies to string format for validation
        const cookieString = cookies.map(c => `${c.name}=${c.value}`).join('; ');
        
        // Validate cookies by making a test API call
        logger.info(`Validating cookies for session ${sessionId}: ${cookieString.substring(0, 100)}...`);

        // Try multiple endpoints for validation
        const endpoints = [
          '/api/v1/users/self',
          '/api/v1/courses',
          '/dashboard'
        ];

        let userData = null;
        let validationSuccess = false;

        for (const endpoint of endpoints) {
          try {
            logger.info(`Trying validation with endpoint: ${endpoint} for session ${sessionId}`);
            const testResponse = await fetch(`${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}${endpoint}`, {
              method: 'GET',
              headers: {
                'Cookie': cookieString,
                'Accept': 'application/json',
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
              },
              timeout: 10000
            });

            logger.info(`Canvas API validation response for ${endpoint} (session ${sessionId}): ${testResponse.status} ${testResponse.statusText}`);

            if (testResponse.ok) {
              if (endpoint === '/api/v1/users/self') {
                userData = await testResponse.json();
                logger.info('Canvas API validation successful for session %s, user: %s', sessionId, userData.name || 'unknown');
              }
              validationSuccess = true;
              break;
            } else {
              const errorText = await testResponse.text();
              logger.warn(`Validation failed for endpoint ${endpoint} (session ${sessionId}): HTTP ${testResponse.status}, Response: ${errorText}`);
              logger.warn(`Response headers: ${JSON.stringify(Object.fromEntries(testResponse.headers.entries()))}`);
            }
          } catch (endpointError) {
            logger.warn(`Validation error for endpoint ${endpoint} (session ${sessionId}): ${endpointError.message}`);
          }
        }

        if (validationSuccess) {
          // Store session in session manager
          sessionManager.addSession(userId, {
            cookies: cookieString,
            username: username,
            loginMethod: 'external_browser',
            userInfo: userData
          });

          // Generate JWT token
          const token = generateToken({ userId, username });

          // Clean up external browser session
          activeExternalLogins.delete(sessionId);

          logger.info('External browser login completed successfully for user: %s', username);

          res.json({
            success: true,
            message: 'Login completed successfully',
            token: token,
            user: {
              id: userData?.id || 1,
              name: userData?.name || username,
              username: username,
              loginMethod: 'external_browser',
              email: userData?.email || username,
              avatar_url: userData?.avatar_url
            }
          });
        } else {
          logger.error(`All cookie validation attempts failed for session ${sessionId}`);
          logger.error(`Cookie string used for validation: ${cookieString.substring(0, 200)}...`);
          logger.error(`Request headers: ${JSON.stringify({
            'Cookie': cookieString.substring(0, 100) + '...',
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
          })}`);
          throw new Error('All cookie validation attempts failed');
        }
      } else {
        logger.error(`No cookies found after login for session: ${sessionId}`);
        throw new Error('No cookies found after login');
      }

      // Close browser
      await browser.close();

    } catch (browserError) {
      logger.error('Browser error during external browser login: %s', browserError.message);
      
      // Clean up session
      activeExternalLogins.delete(sessionId);
      
      res.status(500).json({
        success: false,
        error: 'Browser login failed',
        message: 'Failed to complete login with browser. Please try again.'
      });
    }

  } catch (error) {
    logger.error('Failed to complete external browser login: %s', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to complete external browser login',
      message: error.message
    });
  }
});

/**
 * POST /api/auth/start-webview-login
 * Start WebView login process
 */
router.post('/start-webview-login', applyAuthRateLimit, [
  body('username')
    .notEmpty()
    .withMessage('Username is required')
    .isLength({ min: 3, max: 50 })
    .withMessage('Username must be between 3 and 50 characters')
    .customSanitizer(sanitizeInput)
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { username } = req.body;
    const userId = `user_${username}`;

    logger.info('Starting WebView login for user: %s', username);

    // Store WebView session reference for this user
    req.app.locals.activeWebViewLogins = req.app.locals.activeWebViewLogins || new Map();
    req.app.locals.activeWebViewLogins.set(userId, { 
      username, 
      createdAt: new Date(),
      status: 'waiting_for_login'
    });

    res.json({
      success: true,
      message: 'WebView login session created',
      userId: userId,
      loginUrl: `${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}/login`,
      instructions: 'Please log in to K-LMS in the WebView. The login will be detected automatically.'
    });

  } catch (error) {
    logger.error('Failed to start WebView login: %s', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to start WebView login',
      message: error.message
    });
  }
});

/**
 * POST /api/auth/start-manual-login
 * Start manual login process by launching browser (legacy)
 */
router.post('/start-manual-login', applyAuthRateLimit, [
  body('username')
    .notEmpty()
    .withMessage('Username is required')
    .isLength({ min: 3, max: 50 })
    .withMessage('Username must be between 3 and 50 characters')
    .customSanitizer(sanitizeInput)
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { username } = req.body;
    const userId = `user_${username}`;

    logger.info('Starting manual login for user: %s', username);

    // Launch browser for manual login
    const { browser, page } = await launchManualLoginBrowser(userId);

    // Store browser reference for this user
    req.app.locals.activeLogins = req.app.locals.activeLogins || new Map();
    req.app.locals.activeLogins.set(userId, { browser, page, username });

    res.json({
      success: true,
      message: 'Browser launched for manual login',
      userId: userId,
      instructions: 'Please log in to K-LMS in the opened browser window. The login will be detected automatically.'
    });

  } catch (error) {
    logger.error('Failed to start manual login: %s', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to start manual login',
      message: error.message
    });
  }
});

/**
 * POST /api/auth/complete-webview-login
 * Complete WebView login process with cookies
 */
router.post('/complete-webview-login', applyAuthRateLimit, [
  body('userId')
    .notEmpty()
    .withMessage('User ID is required')
    .customSanitizer(sanitizeInput),
  body('cookies')
    .notEmpty()
    .withMessage('Cookies are required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { userId, cookies } = req.body;

    logger.info('Completing WebView login for user: %s', userId);

    // Get WebView session reference for this user
    const activeWebViewLogins = req.app.locals.activeWebViewLogins || new Map();
    const loginData = activeWebViewLogins.get(userId);

    if (!loginData) {
      return res.status(404).json({
        success: false,
        error: 'No active WebView login session found',
        message: 'Please start a new WebView login process'
      });
    }

    const { username } = loginData;

    try {
      // Validate cookies by making a test API call
      const cookieString = Array.isArray(cookies) 
        ? cookies.map(c => `${c.name}=${c.value}`).join('; ')
        : cookies;

      logger.info('Validating cookies for user %s: %s', userId, cookieString.substring(0, 100) + '...');

      // Try multiple validation approaches
      let userData = null;
      let validationSuccess = false;

      // Method 1: Try with original cookies
      try {
        const testResponse = await fetch(`${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}/api/v1/users/self`, {
          method: 'GET',
          headers: {
            'Cookie': cookieString,
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
          },
          timeout: 10000
        });

        logger.info('Canvas API response status: %s for user %s', testResponse.status, userId);

        if (testResponse.ok) {
          userData = await testResponse.json();
          validationSuccess = true;
        } else {
          const errorText = await testResponse.text();
          logger.warn('Canvas API validation failed for user %s: HTTP %s, Response: %s', userId, testResponse.status, errorText);
        }
      } catch (fetchError) {
        logger.warn('Canvas API fetch failed for user %s: %s', userId, fetchError.message);
      }

      // Method 2: If validation failed, try with minimal cookies (just session cookies)
      if (!validationSuccess && Array.isArray(cookies)) {
        try {
          const sessionCookies = cookies.filter(c => 
            c.name.includes('session') || 
            c.name.includes('canvas') || 
            c.name.includes('csrf') ||
            c.name.includes('_token') ||
            c.name.includes('_canvas_session')
          );

          if (sessionCookies.length > 0) {
            const sessionCookieString = sessionCookies.map(c => `${c.name}=${c.value}`).join('; ');
            logger.info('Trying with session cookies only for user %s: %s', userId, sessionCookieString.substring(0, 100) + '...');

            const testResponse2 = await fetch(`${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}/api/v1/users/self`, {
              method: 'GET',
              headers: {
                'Cookie': sessionCookieString,
                'Accept': 'application/json',
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
              },
              timeout: 10000
            });

            if (testResponse2.ok) {
              userData = await testResponse2.json();
              validationSuccess = true;
              // Use session cookies for storage
              const cookieString = sessionCookieString;
            }
          }
        } catch (fetchError2) {
          logger.warn('Session cookies validation failed for user %s: %s', userId, fetchError2.message);
        }
      }

      // Method 3: If still failed, try with any single cookie that looks important
      if (!validationSuccess && Array.isArray(cookies)) {
        for (const cookie of cookies) {
          if (cookie.name && cookie.value && (
            cookie.name.includes('session') || 
            cookie.name.includes('canvas') || 
            cookie.name.includes('csrf') ||
            cookie.name.includes('_token')
          )) {
            try {
              const singleCookieString = `${cookie.name}=${cookie.value}`;
              logger.info('Trying with single cookie for user %s: %s', userId, singleCookieString);

              const testResponse3 = await fetch(`${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}/api/v1/users/self`, {
                method: 'GET',
                headers: {
                  'Cookie': singleCookieString,
                  'Accept': 'application/json',
                  'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
                },
                timeout: 10000
              });

              if (testResponse3.ok) {
                userData = await testResponse3.json();
                validationSuccess = true;
                // Use single cookie for storage
                const cookieString = singleCookieString;
                break;
              }
            } catch (fetchError3) {
              logger.warn('Single cookie validation failed for user %s: %s', userId, fetchError3.message);
            }
          }
        }
      }

      if (validationSuccess && userData) {
        // Store session in session manager
        sessionManager.addSession(userId, {
          cookies: cookieString,
          username: username,
          loginMethod: 'webview',
          userInfo: userData
        });

        // Generate JWT token
        const token = generateToken({ userId, username });

        // Clean up WebView session
        activeWebViewLogins.delete(userId);

        logger.info('WebView login completed successfully for user: %s', username);

        res.json({
          success: true,
          message: 'Login completed successfully',
          token: token,
          user: {
            id: userData.id || 1,
            name: userData.name || username,
            username: username,
            loginMethod: 'webview',
            email: userData.email || username,
            avatar_url: userData.avatar_url
          }
        });
      } else {
        throw new Error('Cookie validation failed: No valid authentication cookies found');
      }

    } catch (error) {
      // Clean up WebView session on error
      activeWebViewLogins.delete(userId);

      logger.error('WebView login failed for user %s: %s', userId, error.message);
      res.status(400).json({
        success: false,
        error: 'WebView login failed',
        message: error.message
      });
    }

  } catch (error) {
    logger.error('Failed to complete WebView login: %s', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to complete WebView login',
      message: error.message
    });
  }
});

/**
 * POST /api/auth/complete-manual-login
 * Complete manual login process and extract session (legacy)
 */
router.post('/complete-manual-login', applyAuthRateLimit, [
  body('userId')
    .notEmpty()
    .withMessage('User ID is required')
    .customSanitizer(sanitizeInput)
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { userId } = req.body;

    logger.info('Completing manual login for user: %s', userId);

    // Get browser reference for this user
    const activeLogins = req.app.locals.activeLogins || new Map();
    const loginData = activeLogins.get(userId);

    if (!loginData) {
      return res.status(404).json({
        success: false,
        error: 'No active login session found',
        message: 'Please start a new manual login process'
      });
    }

    const { browser, page, username } = loginData;

    try {
      // Wait for manual login completion
      const cookies = await waitForManualLogin(page, userId);

      if (cookies && cookies.length > 0) {
        // Convert cookies array to string format
        const cookieString = cookies.map(c => `${c.name}=${c.value}`).join('; ');
        
        // Store session in session manager
        sessionManager.addSession(userId, {
          cookies: cookieString,
          username: username,
          loginMethod: 'manual'
        });

        // Generate JWT token
        const token = generateToken({ userId, username });

        // Clean up browser
        try {
          await browser.close();
        } catch (closeError) {
          logger.warn('Failed to close browser: %s', closeError.message);
        }
        activeLogins.delete(userId);

        logger.info('Manual login completed successfully for user: %s', username);

        res.json({
          success: true,
          message: 'Login completed successfully',
          token: token,
          user: {
            id: 1, // Use a numeric ID for compatibility with UserModel
            name: username,
            username: username,
            loginMethod: 'manual',
            email: username
          }
        });
      } else {
        throw new Error('No cookies found after login');
      }

    } catch (error) {
      // Clean up browser on error
      try {
        await browser.close();
      } catch (closeError) {
        logger.warn('Failed to close browser: %s', closeError.message);
      }
      activeLogins.delete(userId);

      logger.error('Manual login failed for user %s: %s', userId, error.message);
      res.status(400).json({
        success: false,
        error: 'Manual login failed',
        message: error.message
      });
    }

  } catch (error) {
    logger.error('Failed to complete manual login: %s', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to complete manual login',
      message: error.message
    });
  }
});

/**
 * POST /api/auth/login
 * Login with K-LMS credentials (legacy - redirects to manual login)
 */
router.post('/login', applyAuthRateLimit, [
  body('username')
    .notEmpty()
    .withMessage('Username is required')
    .isLength({ min: 3, max: 50 })
    .withMessage('Username must be between 3 and 50 characters')
    .customSanitizer(sanitizeInput),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
    .isLength({ min: 6, max: 100 })
    .withMessage('Password must be between 6 and 100 characters')
], async (req, res) => {
  try {
    // Validate input
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }
    
    const { username, password } = req.body;
    
    logger.info('Login attempt', { 
      username: username.substring(0, 3) + '***',
      ip: req.ip 
    });
    
    // Attempt login with K-LMS
    const loginResult = await loginToKLMS(username, password);
    
    if (!loginResult.success) {
      logger.warn('Login failed', { 
        username: username.substring(0, 3) + '***',
        error: loginResult.error 
      });
      
      return res.status(401).json({
        success: false,
        error: 'Authentication failed',
        message: 'Invalid username or password'
      });
    }
    
    // Generate user ID (use username for now, could be enhanced)
    const userId = `user_${username}`;
    
    // Store session
    sessionManager.addSession(userId, {
      cookies: loginResult.cookies,
      userInfo: loginResult.userInfo,
      username: username
    });
    
    // Generate JWT token
    const token = generateToken({
      userId: userId,
      username: username,
      loginTime: loginResult.loginTime
    });
    
    logger.info('Login successful', { 
      userId,
      username: username.substring(0, 3) + '***',
      hasUserInfo: !!loginResult.userInfo
    });
    
    res.json({
      success: true,
      token: token,
      user: {
        id: loginResult.userInfo?.id || userId,
        name: loginResult.userInfo?.name || username,
        email: loginResult.userInfo?.email,
        avatar_url: loginResult.userInfo?.avatar_url
      },
      expiresIn: process.env.JWT_EXPIRES_IN || '24h'
    });
    
  } catch (error) {
    logger.error('Login error', { error: error.message, stack: error.stack });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: 'An unexpected error occurred during login'
    });
  }
});

/**
 * POST /api/auth/logout
 * Logout and clear session
 */
router.post('/logout', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        error: 'No token provided'
      });
    }
    
    // Verify token
    const decoded = verifyToken(token);
    const userId = decoded.userId;
    
    // Remove session
    sessionManager.removeSession(userId);
    
    logger.info('Logout successful', { userId });
    
    res.json({
      success: true,
      message: 'Logged out successfully'
    });
    
  } catch (error) {
    logger.error('Logout error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * GET /api/auth/validate
 * Validate current session
 */
router.get('/validate', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        error: 'No token provided'
      });
    }
    
    // Verify token
    const decoded = verifyToken(token);
    const userId = decoded.userId;
    
    // Check if session exists and is valid
    const session = sessionManager.getSession(userId);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        error: 'Session not found or expired'
      });
    }
    
    // Get detailed user information from Canvas API
    let detailedUserInfo = session.userInfo;
    
    try {
      const cookieString = Array.isArray(session.cookies) 
        ? session.cookies.map(c => `${c.name}=${c.value}`).join('; ')
        : session.cookies;
      
      const userResponse = await fetch(`${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}/api/v1/users/self`, {
        method: 'GET',
        headers: {
          'Cookie': cookieString,
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        },
        timeout: 10000
      });
      
      if (userResponse.ok) {
        const userData = await userResponse.json();
        detailedUserInfo = {
          id: userData.id,
          name: userData.name,
          sortable_name: userData.sortable_name,
          short_name: userData.short_name,
          email: userData.email,
          avatar_url: userData.avatar_url,
          locale: userData.locale,
          effective_locale: userData.effective_locale,
          last_login: userData.last_login,
          time_zone: userData.time_zone,
          bio: userData.bio
        };
        
        // Update session with detailed user info
        session.userInfo = detailedUserInfo;
        session.lastValidated = new Date();
      }
    } catch (error) {
      logger.warn('Failed to fetch detailed user info', { userId, error: error.message });
      // Fall back to existing user info
    }
    
    res.json({
      success: true,
      valid: true,
      user: {
        id: detailedUserInfo?.id || 1,
        name: detailedUserInfo?.name || session.username,
        sortable_name: detailedUserInfo?.sortable_name,
        short_name: detailedUserInfo?.short_name,
        email: detailedUserInfo?.email,
        avatar_url: detailedUserInfo?.avatar_url,
        locale: detailedUserInfo?.locale,
        effective_locale: detailedUserInfo?.effective_locale,
        last_login: detailedUserInfo?.last_login,
        time_zone: detailedUserInfo?.time_zone,
        bio: detailedUserInfo?.bio
      },
      sessionInfo: {
        createdAt: session.createdAt,
        lastAccessed: session.lastAccessed,
        lastValidated: session.lastValidated
      }
    });
    
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        error: 'Invalid or expired token'
      });
    }
    
    logger.error('Session validation error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * GET /api/auth/user
 * Get current user information
 */
router.get('/user', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        error: 'No token provided'
      });
    }
    
    // Verify token
    const decoded = verifyToken(token);
    const userId = decoded.userId;
    
    // Get session
    const session = sessionManager.getSession(userId);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        error: 'Session not found or expired'
      });
    }
    
    res.json({
      success: true,
      user: {
        id: session.userInfo?.id || 1, // Use numeric ID for compatibility
        name: session.userInfo?.name || session.username,
        email: session.userInfo?.email,
        avatar_url: session.userInfo?.avatar_url
      }
    });
    
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        error: 'Invalid or expired token'
      });
    }
    
    logger.error('Get user error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});


/**
 * GET /api/auth/sessions (Admin endpoint)
 * Get all active sessions (for debugging)
 */
router.get('/sessions', async (req, res) => {
  try {
    // In production, this should be protected with admin authentication
    if (process.env.NODE_ENV === 'production') {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    const sessions = sessionManager.getActiveSessions();
    
    res.json({
      success: true,
      sessions: sessions,
      totalSessions: sessions.length
    });
    
  } catch (error) {
    logger.error('Get sessions error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Add: In-memory tracking for Puppeteer direct-login sessions
// Map<sessionId, { userId, username, status, startedAt, browser?, page?, manualControlUrl?, token?, user?, error? }>
const ensurePuppeteerMap = (app) => {
  app.locals.activePuppeteerLogins = app.locals.activePuppeteerLogins || new Map();
  return app.locals.activePuppeteerLogins;
};

// Add: Helper to kick off background login flow
async function startBackgroundPuppeteerLogin({ app, sessionId, userId, username }) {
  const activePuppeteerLogins = ensurePuppeteerMap(app);
  const baseUrl = process.env.CANVAS_BASE_URL || 'https://lms.keio.jp';

  try {
    logger.info(`Starting server-side Puppeteer login for session ${sessionId} (user ${username})`);

    const { browser, page } = await launchManualLoginBrowser(userId);

    // Optionally expose a manual control URL (e.g., noVNC) if configured
    const manualControlUrlBase = process.env.NOVNC_BASE_URL;
    const manualControlUrl = manualControlUrlBase
      ? `${manualControlUrlBase}/vnc.html?path=websockify?token=${sessionId}`
      : undefined;

    // Save initial state
    activePuppeteerLogins.set(sessionId, {
      userId,
      username,
      status: 'pending',
      startedAt: Date.now(),
      browser,
      page,
      manualControlUrl,
    });

    // Navigate to portal first (more stable SSO entry), fallback to /login
    try {
      await page.goto(`${baseUrl}/portal.html`, { waitUntil: 'networkidle2', timeout: 60000 });
      logger.info(`Navigated to ${baseUrl}/portal.html for session ${sessionId}`);
    } catch (e) {
      logger.warn(`Failed to open portal.html, falling back to /login for session ${sessionId}: ${e.message}`);
      await page.goto(`${baseUrl}/login`, { waitUntil: 'networkidle2', timeout: 60000 });
    }

    activePuppeteerLogins.get(sessionId).status = 'authenticating';

    // Wait up to 3 minutes for SAML to complete and land back on K-LMS (not auth pages)
    await page.waitForFunction(() => {
      const url = window.location.href;
      return url.includes('lms.keio.jp') &&
             !url.includes('/login') &&
             !url.includes('/portal') &&
             !url.includes('okta.com') &&
             !url.includes('/saml') &&
             !url.includes('/auth');
    }, { timeout: 180000 });

    logger.info(`SAML flow completed for session ${sessionId}, final URL: ${page.url()}`);

    // Multi-method validation: elements and page content
    await page.waitForFunction(() => {
      const url = location.href;
      const q = (s) => document.querySelector(s);
      const text = (t) => document.body && document.body.innerText && document.body.innerText.includes(t);
      const urlOk = url.includes('lms.keio.jp') && !url.includes('/login') && !url.includes('/portal') && !url.includes('okta.com') && !url.includes('/saml') && !url.includes('/auth');
      const formGone = !q('#pseudonym_session_unique_id') && !q('input[type="password"]');
      const userEl = q('#global_nav_profile_link') || q('img[alt*="avatar"]');
      const dashEl = q('#dashboard') || q('.ic-Dashboard');
      const textOk = text('Dashboard') || text('コース') || text('Courses');
      return urlOk && (userEl || dashEl || formGone || textOk);
    }, { timeout: 180000 });

    // Small grace period for cookies to settle
    await new Promise(r => setTimeout(r, 5000));

    // Extract cookies
    const cookies = await page.cookies('https://lms.keio.jp');
    logger.info(`Received ${cookies ? cookies.length : 0} cookies for session ${sessionId}`);

    if (!cookies || cookies.length === 0) {
      throw new Error('No cookies found after login');
    }

    // Build cookie string
    const cookieString = cookies.map(c => `${c.name}=${c.value}`).join('; ');

    // Validate cookies via multiple endpoints
    activePuppeteerLogins.get(sessionId).status = 'validating';

    const endpoints = ['/api/v1/users/self', '/api/v1/courses', '/dashboard'];
    let userData = null;
    let validationSuccess = false;

    for (const endpoint of endpoints) {
      try {
        const resp = await fetch(`${baseUrl}${endpoint}`, {
          method: 'GET',
          headers: {
            'Cookie': cookieString,
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
          },
          timeout: 10000
        });

        logger.info(`Canvas API validation response for ${endpoint} (session ${sessionId}): ${resp.status} ${resp.statusText}`);

        if (resp.ok) {
          if (endpoint === '/api/v1/users/self') {
            try {
              userData = await resp.json();
            } catch (_) {
              // ignore JSON errors for non-JSON endpoints
            }
          }
          validationSuccess = true;
          break;
        } else {
          const bodyText = await resp.text();
          logger.warn(`Validation failed for endpoint ${endpoint} (session ${sessionId}): HTTP ${resp.status}, Response: ${bodyText}`);
        }
      } catch (err) {
        logger.warn(`Validation error for endpoint ${endpoint} (session ${sessionId}): ${err.message}`);
      }
    }

    if (!validationSuccess) {
      throw new Error('All cookie validation attempts failed');
    }

    // Store session server-side
    sessionManager.addSession(userId, {
      cookies: cookieString,
      username,
      loginMethod: 'puppeteer',
      userInfo: userData || undefined
    });

    // Issue JWT token for client to reference session
    const token = generateToken({ userId, username });

    const finalUser = {
      id: userData?.id || 1,
      name: userData?.name || username,
      username,
      loginMethod: 'puppeteer',
      email: userData?.email || username,
      avatar_url: userData?.avatar_url
    };

    // Close browser
    try { await page.close(); } catch (_) {}
    try { await browser.close(); } catch (_) {}

    // Update session state
    activePuppeteerLogins.set(sessionId, {
      userId,
      username,
      status: 'success',
      startedAt: activePuppeteerLogins.get(sessionId)?.startedAt || Date.now(),
      manualControlUrl,
      token,
      user: finalUser,
    });

    logger.info(`Puppeteer login completed successfully for session ${sessionId}`);
  } catch (error) {
    logger.error(`Puppeteer login failed for session ${sessionId}: ${error.message}`);
    const activePuppeteerLogins = ensurePuppeteerMap(app);
    const entry = activePuppeteerLogins.get(sessionId);
    // Attempt to close any resources
    if (entry?.page) { try { await entry.page.close(); } catch (_) {} }
    if (entry?.browser) { try { await entry.browser.close(); } catch (_) {} }

    activePuppeteerLogins.set(sessionId, {
      userId,
      username,
      status: 'failed',
      startedAt: entry?.startedAt || Date.now(),
      manualControlUrl: entry?.manualControlUrl,
      error: error.message
    });
  }
}

// Add: Start Puppeteer direct-login
router.post('/start-puppeteer-login', applyAuthRateLimit, [
  body('username')
    .notEmpty()
    .withMessage('Username is required')
    .isLength({ min: 3, max: 50 })
    .withMessage('Username must be between 3 and 50 characters')
    .customSanitizer(sanitizeInput)
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, error: 'Validation failed', details: errors.array() });
    }

    const { username } = req.body;
    const userId = `user_${username}`;
    const sessionId = `session_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;

    const activePuppeteerLogins = ensurePuppeteerMap(req.app);
    if (activePuppeteerLogins.has(sessionId)) {
      return res.status(409).json({ success: false, error: 'Session ID conflict' });
    }

    // Seed entry
    activePuppeteerLogins.set(sessionId, {
      userId,
      username,
      status: 'pending',
      startedAt: Date.now()
    });

    // Kick off background job (do not await)
    startBackgroundPuppeteerLogin({ app: req.app, sessionId, userId, username });

    // Manual control URL if configured (VNC, etc.) and built-in remote UI URL
    const manualControlUrlBase = process.env.NOVNC_BASE_URL;
    const manualControlUrl = manualControlUrlBase
      ? `${manualControlUrlBase}/vnc.html?path=websockify?token=${sessionId}`
      : undefined;
    const remoteControlUrl = `${req.protocol}://${req.get('host')}/api/auth/remote/${sessionId}`;

    res.json({
      success: true,
      message: 'Puppeteer login started',
      sessionId,
      userId,
      manualControlUrl,
      remoteControlUrl,
    });
  } catch (error) {
    logger.error(`Failed to start Puppeteer login: ${error.message}`);
    res.status(500).json({ success: false, error: 'Failed to start Puppeteer login', message: error.message });
  }
});

// Add: Remote control lightweight UI (HTML)
router.get('/remote/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const activePuppeteerLogins = ensurePuppeteerMap(req.app);
    const entry = activePuppeteerLogins.get(sessionId);

    if (!entry) {
      return res.status(404).send('<h3>Session not found or expired</h3>');
    }

    const html = `<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
<title>K-LMS Remote Login</title>
<style>
  body{margin:0;background:#111;color:#eee;font-family:system-ui,-apple-system,Segoe UI,Roboto}
  #wrap{max-width:900px;margin:0 auto;padding:8px}
  #screen{width:100%;height:auto;border:1px solid #333;border-radius:6px;background:#000}
  #hint{font-size:14px;opacity:.8;margin:8px 0}
  #keys{display:flex;gap:8px;margin:8px 0}
  button{padding:10px 14px;border-radius:6px;border:0;background:#2c64f1;color:#fff}
  input[type=text]{flex:1;padding:10px;border-radius:6px;border:1px solid #444;background:#1b1b1b;color:#fff}
</style>
</head>
<body>
<div id="wrap">
  <div id="hint">画面をタップして操作、テキスト入力は下の欄から送信できます。</div>
  <img id="screen" src="/api/auth/remote/${sessionId}/screen?ts=${Date.now()}" alt="screen" />
  <div id="keys">
    <input id="text" type="text" placeholder="テキストを入力して送信" />
    <button id="send">送信</button>
    <button id="reload">再読込</button>
  </div>
</div>
<script>
  (function(){
    const img = document.getElementById('screen');
    const text = document.getElementById('text');
    const send = document.getElementById('send');
    const reloadBtn = document.getElementById('reload');
    const sid = '${sessionId}';

    function refresh(){
      img.src = '/api/auth/remote/' + sid + '/screen?ts=' + Date.now();
    }
    setInterval(refresh, 700);

    img.addEventListener('click', function(e){
      const rect = img.getBoundingClientRect();
      const x = (e.clientX - rect.left) / rect.width;
      const y = (e.clientY - rect.top) / rect.height;
      fetch('/api/auth/remote/' + sid + '/input', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ type: 'click', x: x, y: y })
      }).catch(function(){});
    });

    send.addEventListener('click', function(){
      if(!text.value) return;
      fetch('/api/auth/remote/' + sid + '/input', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ type: 'text', value: text.value })
      }).then(function(){ text.value=''; }).catch(function(){});
    });

    reloadBtn.addEventListener('click', function(){
      fetch('/api/auth/remote/' + sid + '/input', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ type: 'reload' })
      }).catch(function(){});
    });
  })();
</script>
</body>
</html>`;

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    return res.send(html);
  } catch (error) {
    logger.error(`Remote UI error: ${error.message}`);
    res.status(500).send('Internal server error');
  }
});

// Add: Screenshot endpoint (PNG)
router.get('/remote/:sessionId/screen', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const activePuppeteerLogins = ensurePuppeteerMap(req.app);
    const entry = activePuppeteerLogins.get(sessionId);

    if (!entry || !entry.page) {
      return res.status(404).end();
    }

    try {
      const buf = await entry.page.screenshot({ type: 'png', fullPage: false });
      res.setHeader('Content-Type', 'image/png');
      return res.send(buf);
    } catch (e) {
      logger.warn(`Screenshot error for ${sessionId}: ${e.message}`);
      return res.status(503).end();
    }
  } catch (error) {
    logger.error(`Remote screen error: ${error.message}`);
    res.status(500).end();
  }
});

// Add: Input relay (click/text/reload)
router.post('/remote/:sessionId/input', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const activePuppeteerLogins = ensurePuppeteerMap(req.app);
    const entry = activePuppeteerLogins.get(sessionId);
    if (!entry || !entry.page) {
      return res.status(404).json({ success: false, error: 'Session not found' });
    }

    const body = req.body || {};
    const type = body.type;

    if (type === 'click') {
      const xRatio = Number(body.x);
      const yRatio = Number(body.y);
      const vp = entry.page.viewport() || { width: 1280, height: 720 };
      const x = Math.max(0, Math.min(vp.width - 1, Math.floor(xRatio * vp.width)));
      const y = Math.max(0, Math.min(vp.height - 1, Math.floor(yRatio * vp.height)));
      await entry.page.mouse.click(x, y, { delay: 10 });
      return res.json({ success: true });
    }

    if (type === 'text') {
      const value = String(body.value || '');
      await entry.page.keyboard.type(value, { delay: 20 });
      return res.json({ success: true });
    }

    if (type === 'reload') {
      await entry.page.reload({ waitUntil: 'domcontentloaded' });
      return res.json({ success: true });
    }

    return res.status(400).json({ success: false, error: 'Unsupported input type' });
  } catch (error) {
    logger.error(`Remote input error: ${error.message}`);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

/**
 * GET /api/auth/status/:sessionId
 * Poll status of a Puppeteer direct-login session
 */
router.get('/status/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const activePuppeteerLogins = ensurePuppeteerMap(req.app);
    const entry = activePuppeteerLogins.get(sessionId);

    if (!entry) {
      return res.status(404).json({ success: false, error: 'Session not found' });
    }

    const { status, token, user, manualControlUrl, username, userId, error, startedAt } = entry;
    res.json({ success: true, status, token, user, manualControlUrl, username, userId, error, startedAt });
  } catch (error) {
    logger.error(`Failed to get status: ${error.message}`);
    res.status(500).json({ success: false, error: 'Failed to get status', message: error.message });
  }
});

/**
 * POST /api/auth/cancel/:sessionId
 * Cancel a Puppeteer direct-login session
 */
router.post('/cancel/:sessionId', async (req, res) => {
  try {
    const { sessionId } = req.params;
    const activePuppeteerLogins = ensurePuppeteerMap(req.app);
    const entry = activePuppeteerLogins.get(sessionId);

    if (!entry) {
      return res.status(404).json({ success: false, error: 'Session not found' });
    }

    try { if (entry.page && !entry.page.isClosed()) await entry.page.close(); } catch (_) {}
    try { if (entry.browser) await entry.browser.close(); } catch (_) {}

    activePuppeteerLogins.delete(sessionId);
    res.json({ success: true, message: 'Session canceled' });
  } catch (error) {
    logger.error(`Failed to cancel session: ${error.message}`);
    res.status(500).json({ success: false, error: 'Failed to cancel session', message: error.message });
  }
});

// In-memory single-flight lock for credentials login
const ensureCredsLockMap = (app) => {
  app.locals.credentialsLoginLocks = app.locals.credentialsLoginLocks || new Map();
  return app.locals.credentialsLoginLocks;
};

// Credentials login placed early to avoid any route fall-through
router.post('/credentials-login', applyAuthRateLimit, [
  body('username')
    .notEmpty()
    .withMessage('Username is required')
    .isLength({ min: 3, max: 100 })
    .withMessage('Username length invalid')
    .customSanitizer(sanitizeInput),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
    .isLength({ min: 3, max: 200 })
    .withMessage('Password length invalid')
], async (req, res) => {
  let username = '';
  let password = '';
  let browser = null;
  let page = null;
  const locks = ensureCredsLockMap(req.app);
  let lockKey = '';
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, error: 'Validation failed', details: errors.array() });
    }

    username = String(req.body.username || '');
    password = String(req.body.password || '');
    lockKey = username.toLowerCase();

    // Single-flight per user
    if (locks.get(lockKey) === true) {
      // eslint-disable-next-line no-console
      console.log(`[trace] credentials-login in progress; user=${username.substring(0,3)}***`);
      return res.status(202).json({ success: false, inProgress: true, message: 'Login already in progress' });
    }
    locks.set(lockKey, true);

    const maskedUser = `${username.substring(0, 3)}***`;
    logger.info(`Starting credentials login for user: ${maskedUser}`);
    // eslint-disable-next-line no-console
    console.log(`[trace] credentials-login start user=${maskedUser}`);

    // Launch server-side browser
    const userId = `user_${username}`;
    const started = await launchManualLoginBrowser(userId);
    browser = started.browser;
    page = started.page;

    const baseUrl = process.env.CANVAS_BASE_URL || 'https://lms.keio.jp';

    // Go directly to SAML entry
    try {
      await page.goto(`${baseUrl}/login/saml`, { waitUntil: 'networkidle2', timeout: 60000 });
    } catch (_) {
      await page.goto(`${baseUrl}/login`, { waitUntil: 'networkidle2', timeout: 60000 });
    }
    console.log('[trace] navigated to /login/saml');

    // If we are still on K-LMS selector page, click keio.jp link
    try {
      const keioLink = await page.$x("//a[contains(translate(text(),'KEIO.JP','keio.jp'),'keio.jp')]");
      if (keioLink && keioLink.length > 0) {
        await keioLink[0].click();
        await page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 60000 }).catch(() => {});
      }
    } catch (_) {}

    // Frame-aware utilities
    async function findInFrames(pageRef, selectors) {
      const frames = pageRef.frames();
      for (const frame of frames) {
        for (const sel of selectors) {
          try {
            const h = await frame.$(sel);
            if (h) return h;
          } catch (_) {}
        }
      }
      return null;
    }
    async function clickInFrames(pageRef, selectors) {
      const h = await findInFrames(pageRef, selectors);
      if (h) { await h.click({ delay: 20 }); return true; }
      return false;
    }

    // Selectors
    const usernameSelectors = [
      'input[name="identifier"]',
      '#okta-signin-username',
      'input[type="email"]',
      'input[name="username"]',
      'input[id*="user" i]'
    ];
    const nextButtonSelectors = [
      'button[data-type="next"]', 'input[data-type="next"]', 'input[value="Next"]', 'button[type="submit"]', 'input[type="submit"]'
    ];
    const passwordSelectors = [
      'input[name="credentials.passcode"]', '#okta-signin-password', 'input[name="password"]', 'input[type="password"]', 'input[id*="pass" i]'
    ];
    const signInButtonSelectors = [
      'button[data-type="submit"]', 'input[data-type="submit"]', 'input[value="Sign in"]', 'button[type="submit"]'
    ];
    const mfaIndicators = [
      'input[name="otp"]',
      'input[name="oneTimePassword"]',
      'input[name="verificationCode"]',
      'button[data-se="okta_verify_button"]',
      'div[data-se="okta_verify_push"]'
    ];

    // Username
    console.log('[trace] waiting username field');
    let userInput = await findInFrames(page, usernameSelectors);
    if (!userInput) userInput = await page.$(usernameSelectors[0]);
    if (!userInput) throw new Error('Username field not found');
    await userInput.click({ delay: 20 });
    await page.keyboard.type(username, { delay: 20 });

    // Next (if any)
    console.log('[trace] clicking next (if present)');
    await clickInFrames(page, nextButtonSelectors).catch(()=>{});
    await page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 30000 }).catch(()=>{});

    // Password
    console.log('[trace] waiting password field');
    let passInput = await findInFrames(page, passwordSelectors);
    if (!passInput) passInput = await page.$(passwordSelectors[0]);
    if (!passInput) throw new Error('Password field not found');
    await passInput.click({ delay: 20 });
    await page.keyboard.type(password, { delay: 18 });

    // Sign in
    console.log('[trace] clicking sign-in/submit');
    const clicked = await clickInFrames(page, signInButtonSelectors);
    if (!clicked) { await page.keyboard.press('Enter'); }

    // If MFA is required, fail fast (仕様によりフォールバックなし)
    const mfaFound = await findInFrames(page, mfaIndicators);
    if (mfaFound) {
      throw new Error('MFA required');
    }

    console.log('[trace] submitted; waiting SAML completion');

    // SAML wait (3 min)
    await page.waitForFunction(() => {
      const url = window.location.href;
      return url.includes('lms.keio.jp') && !url.includes('/login') && !url.includes('/portal') && !url.includes('okta.com') && !url.includes('/saml') && !url.includes('/auth');
    }, { timeout: 180000 });

    await new Promise(r => setTimeout(r, 5000));

    // Cookies
    const cookies = await page.cookies('https://lms.keio.jp');
    console.log(`[trace] cookies count=${cookies ? cookies.length : 0}`);

    if (!cookies || cookies.length === 0) throw new Error('No cookies found after login');
    const cookieString = cookies.map(c => `${c.name}=${c.value}`).join('; ');

    // Validate
    const endpoints = ['/api/v1/users/self', '/api/v1/courses', '/dashboard'];
    let userData = null; let ok = false;
    for (const ep of endpoints) {
      try {
        const resp = await fetch(`${baseUrl}${ep}`, { method: 'GET', headers: { 'Cookie': cookieString, 'Accept': 'application/json', 'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36' }, timeout: 10000 });
        logger.info(`Canvas API validation response for ${ep}: ${resp.status} ${resp.statusText}`);
        console.log(`[trace] validate ${ep}: ${resp.status}`);
        if (resp.ok) { if (ep === '/api/v1/users/self') { try { userData = await resp.json(); } catch(_){} } ok = true; break; }
      } catch(e) { logger.warn(`Validation error for ${ep}: ${e.message}`); console.log(`[trace] validate error ${ep}: ${e.message}`); }
    }
    if (!ok) throw new Error('All cookie validation attempts failed');

    // Session & token
    sessionManager.addSession(userId, { cookies: cookieString, username, loginMethod: 'credentials', userInfo: userData || undefined });
    const token = generateToken({ userId, username });

    // Cleanup & zeroize
    try { await page.close(); } catch(_) {}
    try { await browser.close(); } catch(_) {}
    password = ''.padEnd(password.length, '\\0');

    return res.json({ success: true, token, user: { id: userData?.id || 1, name: userData?.name || username, username, loginMethod: 'credentials', email: userData?.email || username, avatar_url: userData?.avatar_url } });
  } catch (error) {
    const maskedUser = username ? `${username.substring(0, 3)}***` : '***';
    logger.error(`Credentials login failed for user ${maskedUser}: ${error.message}`);
    console.log(`[trace] credentials-login failed user=${maskedUser} reason=${error.message}`);
    try { if (page) await page.close(); } catch(_) {}
    try { if (browser) await browser.close(); } catch(_) {}
    if (password) password = ''.padEnd(password.length, '\\0');
    return res.status(400).json({ success: false, error: 'Credentials login failed', message: 'アプリ内で失敗しました。もう一度お試しください。' });
  } finally {
    if (lockKey) locks.delete(lockKey);
  }
});

// (Disabled old duplicate route to avoid conflicts)
router.post('/__disabled_credentials_login', (req, res) => res.status(404).json({ success:false, error:'Disabled' }));

module.exports = router;
