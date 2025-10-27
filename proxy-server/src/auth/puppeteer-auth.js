const puppeteer = require('puppeteer');
const logger = require('../utils/logger');

const CANVAS_BASE_URL = process.env.CANVAS_BASE_URL || 'https://lms.keio.jp';

/**
 * Launches a browser for manual K-LMS login.
 * User will manually log in through the browser interface.
 * @param {string} userId - User ID for session management.
 * @returns {Promise<object>} A promise that resolves to browser and page objects.
 */
async function launchManualLoginBrowser(userId) {
  logger.info('Launching manual login browser for user: %s', userId);
  
  try {
    // Launch browser with headless mode for VPS server-side operation
    // This ensures the browser runs only on the proxy server
    const browser = await puppeteer.launch({
      headless: true, // Run headless on VPS server
      args: [
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--disable-gpu',
        '--no-first-run',
        '--disable-blink-features=AutomationControlled',
        '--disable-web-security',
        '--disable-features=VizDisplayCompositor',
        '--remote-debugging-port=0', // Use random port
        '--disable-background-timer-throttling',
        '--disable-backgrounding-occluded-windows',
        '--disable-renderer-backgrounding',
        '--disable-extensions',
        '--disable-plugins',
        '--memory-pressure-off',
        '--max_old_space_size=4096', // Increase memory limit
        '--single-process', // Use single process for VPS
        '--disable-background-networking',
        '--disable-default-apps',
        '--disable-sync',
        '--disable-translate',
        '--hide-scrollbars',
        '--metrics-recording-only',
        '--mute-audio',
        '--no-default-browser-check',
        '--no-pings',
        '--password-store=basic',
        '--use-mock-keychain'
      ],
      defaultViewport: { width: 1280, height: 720 },
      timeout: 60000, // Increase timeout for VPS
    });
    
    const page = await browser.newPage();
    
    // Set user agent to avoid detection
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    
    // Navigate to K-LMS login page
    await page.goto(`${CANVAS_BASE_URL}/login`, { 
      waitUntil: 'networkidle2',
      timeout: 60000 // Increase timeout for VPS
    });
    
    logger.info('Browser launched for manual login. User should log in manually.');
    
    return { browser, page };
  } catch (error) {
    logger.error('Failed to launch manual login browser: %s', error.message);
    throw new Error(`Failed to launch browser: ${error.message}`);
  }
}

/**
 * Waits for user to complete manual login and extracts cookies.
 * @param {object} page - Puppeteer page object.
 * @param {string} userId - User ID for session management.
 * @returns {Promise<Array<object>>} A promise that resolves to an array of cookies.
 */
async function waitForManualLogin(page, userId) {
  logger.info('Waiting for manual login completion for user: %s', userId);
  
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      reject(new Error('Manual login timeout after 10 minutes'));
    }, 10 * 60 * 1000); // 10 minutes timeout
    
    // Check every 5 seconds if user has logged in (increased interval to reduce load)
    const checkInterval = setInterval(async () => {
      try {
        // Check if page is still valid
        if (page.isClosed()) {
          clearTimeout(timeout);
          clearInterval(checkInterval);
          reject(new Error('Browser page was closed'));
          return;
        }
        
        const currentUrl = page.url();
        logger.debug('Checking login status for user %s at URL: %s', userId, currentUrl);
        
        // Check if we're on the Canvas dashboard (logged in)
        // More comprehensive login success detection
        const isLoginSuccess = 
          currentUrl.includes('/dashboard') || 
          currentUrl.includes('/courses') ||
          currentUrl.includes('/profile') ||
          currentUrl.includes('/calendar') ||
          currentUrl.includes('/grades') ||
          currentUrl.includes('/notifications') ||
          currentUrl.includes('/conversations') ||
          currentUrl.includes('/settings') ||
          currentUrl.includes('/login_success=1') ||
          currentUrl === CANVAS_BASE_URL ||
          currentUrl === `${CANVAS_BASE_URL}/` ||
          (currentUrl.startsWith(CANVAS_BASE_URL) && 
           !currentUrl.includes('/login') && 
           !currentUrl.includes('/auth') && 
           !currentUrl.includes('/saml') &&
           !currentUrl.includes('/idp'));
        
        if (isLoginSuccess) {
          
          clearTimeout(timeout);
          clearInterval(checkInterval);
          
          logger.info('Manual login detected for user: %s at URL: %s', userId, currentUrl);
          
          // Wait longer to ensure all cookies are set and page is fully loaded
          // SAML authentication may take time to set all cookies
          await new Promise(resolve => setTimeout(resolve, 8000));
          
          try {
            // Extract cookies with explicit domain specification
            const cookies = await page.cookies('https://lms.keio.jp');
            
            // Log all cookies for debugging
            logger.info('All cookies found for user %s:', userId);
            cookies.forEach(cookie => {
              logger.info('Cookie: %s=%s (domain: %s, path: %s, secure: %s, httpOnly: %s)', 
                cookie.name, cookie.value.substring(0, 20) + '...', cookie.domain, cookie.path, cookie.secure, cookie.httpOnly);
            });
            
            // Filter important cookies - more comprehensive filtering
            const importantCookies = cookies.filter(cookie => 
              cookie.name.includes('session') ||
              cookie.name.includes('canvas') ||
              cookie.name.includes('csrf') ||
              cookie.name.includes('_token') ||
              cookie.name.includes('_session') ||
              cookie.name.includes('_canvas_session') ||
              cookie.name.includes('_authenticity_token') ||
              cookie.name.includes('_csrf_token') ||
              cookie.name.includes('canvas_session') ||
              cookie.name.includes('_session_id') ||
              cookie.name.includes('remember_token') ||
              cookie.name.includes('logged_in')
            );
            
            logger.info('Filtered %d important cookies from %d total cookies for user: %s', importantCookies.length, cookies.length, userId);
            
            if (importantCookies.length > 0) {
              logger.info('Successfully extracted %d important cookies for user: %s', importantCookies.length, userId);
              resolve(importantCookies);
            } else {
              logger.warn('No important cookies found, returning all cookies for user: %s', userId);
              resolve(cookies);
            }
          } catch (cookieError) {
            logger.error('Failed to extract cookies: %s', cookieError.message);
            reject(new Error('Failed to extract cookies after login'));
          }
        }
      } catch (error) {
        logger.error('Error during login check: %s', error.message);
        clearTimeout(timeout);
        clearInterval(checkInterval);
        reject(error);
      }
    }, 5000); // Increased to 5 seconds
  });
}

/**
 * Validates if the current session is still active by making a test API call.
 * @param {Array<object>} cookies - Array of cookies to validate.
 * @returns {Promise<object>} Validation result with valid flag and optional error.
 */
async function validateSession(cookies) {
  try {
    // Handle both array and string formats
    const cookieString = Array.isArray(cookies)
      ? cookies.map(c => `${c.name}=${c.value}`).join('; ')
      : cookies;
    
    logger.info('Validating session with cookies: %s', cookieString.substring(0, 100) + '...');
    
    // Try multiple endpoints to validate session
    const endpoints = [
      '/api/v1/users/self',
      '/api/v1/courses',
      '/dashboard'
    ];
    
    for (const endpoint of endpoints) {
      try {
        const response = await fetch(`${CANVAS_BASE_URL}${endpoint}`, {
          headers: {
            'Cookie': cookieString,
            'Accept': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'X-Requested-With': 'XMLHttpRequest'
          },
          timeout: 10000
        });
        
        logger.info('Session validation response for %s: %d %s', endpoint, response.status, response.statusText);
        
        if (response.ok) {
          let userInfo = null;
          try {
            if (endpoint === '/api/v1/users/self') {
              userInfo = await response.json();
            }
          } catch (jsonError) {
            logger.warn('Failed to parse JSON response: %s', jsonError.message);
          }
          
          return {
            valid: true,
            userInfo: userInfo,
            validatedEndpoint: endpoint
          };
        } else if (response.status === 401 || response.status === 403) {
          // Authentication failed
          return {
            valid: false,
            error: `Authentication failed: HTTP ${response.status}: ${response.statusText}`,
            validatedEndpoint: endpoint
          };
        }
      } catch (endpointError) {
        logger.warn('Failed to validate with endpoint %s: %s', endpoint, endpointError.message);
        continue;
      }
    }
    
    // If all endpoints failed
    return {
      valid: false,
      error: 'All validation endpoints failed'
    };
  } catch (error) {
    logger.warn('Session validation failed: %s', error.message);
    return {
      valid: false,
      error: error.message
    };
  }
}

/**
 * Wait for external browser login completion and return cookies
 * @param {object} page - Puppeteer page object
 * @param {string} userId - User ID for session management
 * @param {string} sessionId - Session ID for tracking
 * @returns {Promise<Array>} Array of cookies
 */
async function waitForExternalBrowserLogin(page, userId, sessionId) {
  logger.info('Waiting for external browser login completion for user: %s, session: %s', userId, sessionId);

  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      reject(new Error('External browser login timeout after 5 minutes'));
    }, 5 * 60 * 1000); // 5 minutes timeout

    const checkInterval = setInterval(async () => {
      try {
        const currentUrl = page.url();
        
        // Check if user has successfully logged in
        const isLoginSuccess =
          currentUrl.includes('/dashboard') ||
          currentUrl.includes('/courses') ||
          currentUrl.includes('/profile') ||
          currentUrl.includes('/calendar') ||
          currentUrl.includes('/grades') ||
          currentUrl.includes('/notifications') ||
          currentUrl.includes('/conversations') ||
          currentUrl.includes('/settings') ||
          currentUrl.includes('/login_success=1') ||
          currentUrl === CANVAS_BASE_URL ||
          currentUrl === `${CANVAS_BASE_URL}/`;

        if (isLoginSuccess) {
          clearTimeout(timeout);
          clearInterval(checkInterval);

          logger.info('External browser login detected for user: %s at URL: %s', userId, currentUrl);

          // Wait a bit for cookies to be set
          // SAML authentication may take time to set all cookies
          await new Promise(resolve => setTimeout(resolve, 5000));

          try {
            // Extract cookies with explicit domain specification
            const cookies = await page.cookies('https://lms.keio.jp');

            // Log all cookies for debugging
            logger.info('All cookies found for user %s (external browser):', userId);
            cookies.forEach(cookie => {
              logger.info('Cookie: %s=%s (domain: %s, path: %s, secure: %s, httpOnly: %s)', 
                cookie.name, cookie.value.substring(0, 20) + '...', cookie.domain, cookie.path, cookie.secure, cookie.httpOnly);
            });

            // Filter important cookies - more comprehensive filtering
            const importantCookies = cookies.filter(cookie =>
              cookie.name.includes('session') ||
              cookie.name.includes('canvas') ||
              cookie.name.includes('csrf') ||
              cookie.name.includes('_token') ||
              cookie.name.includes('_session') ||
              cookie.name.includes('_canvas_session') ||
              cookie.name.includes('_authenticity_token') ||
              cookie.name.includes('_csrf_token') ||
              cookie.name.includes('canvas_session') ||
              cookie.name.includes('_session_id') ||
              cookie.name.includes('remember_token') ||
              cookie.name.includes('logged_in')
            );

            logger.info('Filtered %d important cookies from %d total cookies for user: %s (external browser)', importantCookies.length, cookies.length, userId);

            if (importantCookies.length > 0) {
              logger.info('Successfully extracted %d important cookies for user: %s', importantCookies.length, userId);
              
              // Close the browser to signal completion
              await page.close();
              await browser.close();
              
              resolve(importantCookies);
            } else {
              logger.warn('No important cookies found, returning all cookies for user: %s', userId);
              
              // Close the browser to signal completion
              await page.close();
              await browser.close();
              
              resolve(cookies);
            }
          } catch (cookieError) {
            logger.error('Failed to extract cookies: %s', cookieError.message);
            reject(new Error('Failed to extract cookies after login'));
          }
        }
      } catch (error) {
        logger.error('Error checking external browser login status: %s', error.message);
        // Continue checking...
      }
    }, 3000); // Check every 3 seconds
  });
}

/**
 * Legacy function for backward compatibility - now redirects to manual login
 * @param {string} username - Username (not used in manual login)
 * @param {string} password - Password (not used in manual login)
 * @returns {Promise<object>} Login result
 */
async function loginToKLMS(username, password) {
  logger.warn('loginToKLMS called - redirecting to manual login flow');
  
  return {
    success: false,
    error: 'Manual login required. Please use the manual login endpoint.',
    requiresManualLogin: true
  };
}

module.exports = {
  launchManualLoginBrowser,
  waitForManualLogin,
  waitForExternalBrowserLogin,
  validateSession,
  loginToKLMS, // For backward compatibility
};