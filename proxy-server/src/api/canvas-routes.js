const express = require('express');
const { verifyToken } = require('../utils/security');
const sessionManager = require('../auth/session-manager');
const logger = require('../utils/logger');

const router = express.Router();

// Middleware to authenticate requests
const authenticateToken = (req, res, next) => {
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
    req.user = decoded;
    next();
    
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        error: 'Invalid or expired token'
      });
    }
    
    logger.error('Token verification error', { error: error.message });
    return res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
};

// Apply authentication to all routes
router.use(authenticateToken);

/**
 * Make authenticated request to Canvas API using fetch
 * @param {string} endpoint - Canvas API endpoint
 * @param {string} cookies - Session cookies
 * @param {Object} options - Request options
 * @returns {Promise<Object>} - Response data
 */
async function makeCanvasRequest(endpoint, cookies, options = {}) {
  try {
    // Use fetch instead of Puppeteer for better reliability
    // Ensure all requests go to Canvas API v1 endpoints
    const normalizedEndpoint = endpoint.startsWith('/api/v1')
      ? endpoint
      : `/api/v1${endpoint}`;
    const url = `${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}${normalizedEndpoint}`;
    
    const baseHeaders = {
      'Cookie': cookies,
      'Accept': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'X-Requested-With': 'XMLHttpRequest',
      'Accept-Language': 'ja-JP,ja;q=0.9,en-US;q=0.8,en;q=0.7',
    };

    const response = await fetch(url, {
      method: options.method || 'GET',
      headers: { ...(options.headers || {}), ...baseHeaders },
      timeout: 30000
    });
    
    if (response.status === 401) {
      throw new Error('Session expired');
    }
    
    if (response.status === 404) {
      throw new Error(`Canvas API returned status ${response.status} - Resource not found`);
    }
    
    if (response.status === 406) {
      throw new Error(`Canvas API returned status ${response.status} - Not Acceptable`);
    }
    
    if (response.status !== 200) {
      throw new Error(`Canvas API returned status ${response.status}`);
    }
    
    const data = await response.json();
    
    return {
      success: true,
      data: data,
      status: response.status
    };
    
  } catch (error) {
    logger.error('Canvas API request failed', { 
      endpoint, 
      error: error.message 
    });
    
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * GET /api/courses
 * Get user's courses
 */
router.get('/courses', async (req, res) => {
  try {
    const userId = req.user.userId;
    const session = sessionManager.getSession(userId);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        error: 'Session not found or expired'
      });
    }
    
    // Build query string manually to preserve array parameters
    const queryParts = [];
    for (const [key, value] of Object.entries(req.query)) {
      if (Array.isArray(value)) {
        value.forEach(v => queryParts.push(`${key}=${encodeURIComponent(v)}`));
      } else {
        queryParts.push(`${key}=${encodeURIComponent(value)}`);
      }
    }
    const queryString = queryParts.length > 0 ? queryParts.join('&') : '';
    const endpoint = `/courses${queryString ? '?' + queryString : ''}`;
    
    logger.info('Fetching courses', { userId, endpoint });
    
    const result = await makeCanvasRequest(endpoint, session.cookies);
    
    if (!result.success) {
      if (result.error === 'Session expired') {
        sessionManager.removeSession(userId);
        return res.status(401).json({
          success: false,
          error: 'Session expired, please login again'
        });
      }
      
      return res.status(500).json({
        success: false,
        error: 'Failed to fetch courses',
        details: result.error
      });
    }
    
    res.json({
      success: true,
      data: result.data
    });
    
  } catch (error) {
    logger.error('Courses endpoint error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * GET /api/courses/:id
 * Get specific course details
 */
router.get('/courses/:id', async (req, res) => {
  try {
    const userId = req.user.userId;
    const courseId = req.params.id;
    const session = sessionManager.getSession(userId);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        error: 'Session not found or expired'
      });
    }
    
    // Build query string manually to preserve array parameters
    const queryParts = [];
    for (const [key, value] of Object.entries(req.query)) {
      if (Array.isArray(value)) {
        value.forEach(v => queryParts.push(`${key}=${encodeURIComponent(v)}`));
      } else {
        queryParts.push(`${key}=${encodeURIComponent(value)}`);
      }
    }
    const queryString = queryParts.length > 0 ? queryParts.join('&') : '';
    const endpoint = `/courses/${courseId}${queryString ? '?' + queryString : ''}`;
    
    logger.info('Fetching course details', { userId, courseId, endpoint });
    
    const result = await makeCanvasRequest(endpoint, session.cookies);
    
    if (!result.success) {
      if (result.error === 'Session expired') {
        sessionManager.removeSession(userId);
        return res.status(401).json({
          success: false,
          error: 'Session expired, please login again'
        });
      }
      
      return res.status(500).json({
        success: false,
        error: 'Failed to fetch course details',
        details: result.error
      });
    }
    
    res.json({
      success: true,
      data: result.data
    });
    
  } catch (error) {
    logger.error('Course details endpoint error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * GET /api/courses/:id/assignments
 * Get assignments for a specific course
 */
router.get('/courses/:id/assignments', async (req, res) => {
  try {
    const userId = req.user.userId;
    const courseId = req.params.id;
    const session = sessionManager.getSession(userId);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        error: 'Session not found or expired'
      });
    }
    
    // Build query string manually to preserve array parameters like include[]
    const queryParts = [];
    for (const [key, value] of Object.entries(req.query)) {
      if (Array.isArray(value)) {
        value.forEach(v => queryParts.push(`${key}=${encodeURIComponent(v)}`));
      } else {
        queryParts.push(`${key}=${encodeURIComponent(value)}`);
      }
    }
    const queryString = queryParts.length > 0 ? queryParts.join('&') : '';
    const endpoint = `/courses/${courseId}/assignments${queryString ? '?' + queryString : ''}`;
    
    logger.info('Fetching course assignments', { userId, courseId, endpoint, query: req.query });
    
    const result = await makeCanvasRequest(endpoint, session.cookies, {
      headers: {
        // Set referer to course page to mimic browser navigation context
        'Referer': `${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}/courses/${courseId}`,
      }
    });

    if (result.success) {
      logger.info('Fetched course assignments result', {
        userId,
        courseId,
        count: Array.isArray(result.data) ? result.data.length : -1,
        type: typeof result.data
      });
    }
    
    if (!result.success) {
      if (result.error === 'Session expired') {
        sessionManager.removeSession(userId);
        return res.status(401).json({
          success: false,
          error: 'Session expired, please login again'
        });
      }

      // Propagate Canvas error with appropriate status when possible
      const statusMatch = /status\s(\d{3})/.exec(result.error || '');
      const status = statusMatch ? parseInt(statusMatch[1], 10) : 500;
      logger.warn('Canvas assignments fetch failed', { userId, courseId, error: result.error, status });
      return res.status(status).json({
        success: false,
        error: 'Failed to fetch assignments',
        details: result.error
      });
    }
    
    res.json({
      success: true,
      data: result.data
    });
    
  } catch (error) {
    logger.error('Course assignments endpoint error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * GET /api/courses/:id/modules
 * Get modules for a specific course
 */
router.get('/courses/:id/modules', async (req, res) => {
  try {
    const userId = req.user.userId;
    const courseId = req.params.id;
    const session = sessionManager.getSession(userId);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        error: 'Session not found or expired'
      });
    }
    
    // Build query string manually to preserve array parameters like include[]
    const queryParts = [];
    for (const [key, value] of Object.entries(req.query)) {
      if (Array.isArray(value)) {
        value.forEach(v => queryParts.push(`${key}=${encodeURIComponent(v)}`));
      } else {
        queryParts.push(`${key}=${encodeURIComponent(value)}`);
      }
    }
    const queryString = queryParts.length > 0 ? queryParts.join('&') : '';
    const endpoint = `/courses/${courseId}/modules${queryString ? '?' + queryString : ''}`;
    
    logger.info('Fetching course modules', { userId, courseId, endpoint, query: req.query });
    
    const result = await makeCanvasRequest(endpoint, session.cookies, {
      headers: {
        // Set referer to course page to mimic browser navigation context
        'Referer': `${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}/courses/${courseId}`,
      }
    });

    if (result.success) {
      logger.info('Fetched course modules result', {
        userId,
        courseId,
        count: Array.isArray(result.data) ? result.data.length : -1,
        type: typeof result.data
      });
    }
    
    if (!result.success) {
      if (result.error === 'Session expired') {
        sessionManager.removeSession(userId);
        return res.status(401).json({
          success: false,
          error: 'Session expired, please login again'
        });
      }

      // Propagate Canvas error with appropriate status when possible
      const statusMatch = /status\s(\d{3})/.exec(result.error || '');
      const status = statusMatch ? parseInt(statusMatch[1], 10) : 500;
      logger.warn('Canvas modules fetch failed', { userId, courseId, error: result.error, status });
      return res.status(status).json({
        success: false,
        error: 'Failed to fetch modules',
        details: result.error
      });
    }
    
    res.json({
      success: true,
      data: result.data
    });
    
  } catch (error) {
    logger.error('Course modules endpoint error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * GET /api/courses/:courseId/pages/:pageUrl
 * Get page content for a specific course
 */
router.get('/courses/:courseId/pages/:pageUrl', async (req, res) => {
  try {
    const userId = req.user.userId;
    const courseId = req.params.courseId;
    const pageUrl = req.params.pageUrl;
    const session = sessionManager.getSession(userId);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        error: 'Session not found or expired'
      });
    }
    
    const endpoint = `/courses/${courseId}/pages/${pageUrl}`;
    
    logger.info('Fetching page content', { userId, courseId, pageUrl, endpoint });
    
    const result = await makeCanvasRequest(endpoint, session.cookies, {
      headers: {
        'Referer': `${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}/courses/${courseId}`,
      }
    });

    if (result.success) {
      logger.info('Fetched page content result', {
        userId,
        courseId,
        pageUrl,
        hasBody: !!result.data?.body
      });
    }
    
    if (!result.success) {
      if (result.error === 'Session expired') {
        sessionManager.removeSession(userId);
        return res.status(401).json({
          success: false,
          error: 'Session expired, please login again'
        });
      }

      const statusMatch = /status\s(\d{3})/.exec(result.error || '');
      const status = statusMatch ? parseInt(statusMatch[1], 10) : 500;
      logger.warn('Canvas page fetch failed', { userId, courseId, pageUrl, error: result.error, status });
      return res.status(status).json({
        success: false,
        error: 'Failed to fetch page content',
        details: result.error
      });
    }
    
    res.json({
      success: true,
      data: result.data
    });
    
  } catch (error) {
    logger.error('Page content endpoint error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * GET /api/courses/:courseId/files/:fileId
 * Get file information for a specific course
 */
router.get('/courses/:courseId/files/:fileId', async (req, res) => {
  try {
    const userId = req.user.userId;
    const courseId = req.params.courseId;
    const fileId = req.params.fileId;
    const session = sessionManager.getSession(userId);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        error: 'Session not found or expired'
      });
    }
    
    const endpoint = `/courses/${courseId}/files/${fileId}`;
    
    logger.info('Fetching file information', { userId, courseId, fileId, endpoint });
    
    const result = await makeCanvasRequest(endpoint, session.cookies, {
      headers: {
        'Referer': `${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}/courses/${courseId}`,
      }
    });

    if (result.success) {
      logger.info('Fetched file information result', {
        userId,
        courseId,
        fileId,
        displayName: result.data?.display_name,
        mimeClass: result.data?.mime_class
      });
    }
    
    if (!result.success) {
      if (result.error === 'Session expired') {
        sessionManager.removeSession(userId);
        return res.status(401).json({
          success: false,
          error: 'Session expired, please login again'
        });
      }

      const statusMatch = /status\s(\d{3})/.exec(result.error || '');
      const status = statusMatch ? parseInt(statusMatch[1], 10) : 500;
      logger.warn('Canvas file fetch failed', { userId, courseId, fileId, error: result.error, status });
      return res.status(status).json({
        success: false,
        error: 'Failed to fetch file information',
        details: result.error
      });
    }
    
    res.json({
      success: true,
      data: result.data
    });
    
  } catch (error) {
    logger.error('File information endpoint error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * GET /api/assignments/:id
 * Get specific assignment details
 */
router.get('/assignments/:id', async (req, res) => {
  try {
    const userId = req.user.userId;
    const assignmentId = req.params.id;
    const session = sessionManager.getSession(userId);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        error: 'Session not found or expired'
      });
    }
    
    const queryParams = new URLSearchParams(req.query).toString();
    const endpoint = `/assignments/${assignmentId}${queryParams ? '?' + queryParams : ''}`;
    
    logger.info('Fetching assignment details', { userId, assignmentId, endpoint });
    
    const result = await makeCanvasRequest(endpoint, session.cookies);
    
    if (!result.success) {
      if (result.error === 'Session expired') {
        sessionManager.removeSession(userId);
        return res.status(401).json({
          success: false,
          error: 'Session expired, please login again'
        });
      }
      
      return res.status(500).json({
        success: false,
        error: 'Failed to fetch assignment details',
        details: result.error
      });
    }
    
    res.json({
      success: true,
      data: result.data
    });
    
  } catch (error) {
    logger.error('Assignment details endpoint error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * GET /api/courses/:courseId/assignments/:assignmentId
 * Get specific assignment details for a course
 */
router.get('/courses/:courseId/assignments/:assignmentId', async (req, res) => {
  try {
    const userId = req.user.userId;
    const courseId = req.params.courseId;
    const assignmentId = req.params.assignmentId;
    const session = sessionManager.getSession(userId);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        error: 'Session not found or expired'
      });
    }
    
    const queryParams = new URLSearchParams(req.query).toString();
    const endpoint = `/courses/${courseId}/assignments/${assignmentId}${queryParams ? '?' + queryParams : ''}`;
    
    logger.info('Fetching assignment details', { userId, courseId, assignmentId, endpoint });
    
    const result = await makeCanvasRequest(endpoint, session.cookies, {
      headers: {
        'Referer': `${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}/courses/${courseId}`,
      }
    });
    
    if (!result.success) {
      if (result.error === 'Session expired') {
        sessionManager.removeSession(userId);
        return res.status(401).json({
          success: false,
          error: 'Session expired, please login again'
        });
      }
      
      const statusMatch = /status\s(\d{3})/.exec(result.error || '');
      const status = statusMatch ? parseInt(statusMatch[1], 10) : 500;
      logger.warn('Canvas assignment fetch failed', { 
        userId, 
        courseId, 
        assignmentId, 
        error: result.error, 
        status 
      });
      return res.status(status).json({
        success: false,
        error: 'Failed to fetch assignment details',
        details: result.error
      });
    }
    
    res.json({
      success: true,
      data: result.data
    });
    
  } catch (error) {
    logger.error('Assignment details endpoint error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * GET /api/calendar_events
 * Get user's calendar events
 */
router.get('/calendar_events', async (req, res) => {
  try {
    const userId = req.user.userId;
    const session = sessionManager.getSession(userId);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        error: 'Session not found or expired'
      });
    }
    
    // Build query string manually to preserve array parameters
    const queryParts = [];
    for (const [key, value] of Object.entries(req.query)) {
      if (Array.isArray(value)) {
        value.forEach(v => queryParts.push(`${key}=${encodeURIComponent(v)}`));
      } else {
        queryParts.push(`${key}=${encodeURIComponent(value)}`);
      }
    }
    const queryString = queryParts.length > 0 ? queryParts.join('&') : '';
    const endpoint = `/calendar_events${queryString ? '?' + queryString : ''}`;
    
    logger.info('Fetching calendar events', { userId, endpoint });
    
    const result = await makeCanvasRequest(endpoint, session.cookies);
    
    if (!result.success) {
      if (result.error === 'Session expired') {
        sessionManager.removeSession(userId);
        return res.status(401).json({
          success: false,
          error: 'Session expired, please login again'
        });
      }
      
      return res.status(500).json({
        success: false,
        error: 'Failed to fetch calendar events',
        details: result.error
      });
    }
    
    res.json({
      success: true,
      data: result.data
    });
    
  } catch (error) {
    logger.error('Calendar events endpoint error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * GET /api/users/self
 * Get current user information
 */
router.get('/users/self', async (req, res) => {
  try {
    const userId = req.user.userId;
    const session = sessionManager.getSession(userId);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        error: 'Session not found or expired'
      });
    }
    
    const queryParams = new URLSearchParams(req.query).toString();
    const endpoint = `/users/self${queryParams ? '?' + queryParams : ''}`;
    
    logger.info('Fetching user info', { userId, endpoint });
    
    const result = await makeCanvasRequest(endpoint, session.cookies);
    
    if (!result.success) {
      if (result.error === 'Session expired') {
        sessionManager.removeSession(userId);
        return res.status(401).json({
          success: false,
          error: 'Session expired, please login again'
        });
      }
      
      return res.status(500).json({
        success: false,
        error: 'Failed to fetch user information',
        details: result.error
      });
    }
    
    res.json({
      success: true,
      data: result.data
    });
    
  } catch (error) {
    logger.error('User info endpoint error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * GET /api/session/cookies
 * Get session cookies for WebView
 */
router.get('/session/cookies', async (req, res) => {
  try {
    const userId = req.user.userId;
    const session = sessionManager.getSession(userId);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        error: 'Session not found or expired'
      });
    }
    
    logger.info('Getting session cookies for WebView', { userId });
    
    // Parse cookies string into array of cookie objects
    const cookiesArray = session.cookies.split(';').map(cookie => {
      const [name, ...valueParts] = cookie.trim().split('=');
      return {
        name: name.trim(),
        value: valueParts.join('=').trim(),
        domain: '.keio.jp',
        path: '/'
      };
    }).filter(cookie => cookie.name && cookie.value);
    
    res.json({
      success: true,
      data: {
        cookies: cookiesArray,
        baseUrl: process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'
      }
    });
    
  } catch (error) {
    logger.error('Session cookies endpoint error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Download file endpoint (returns binary data)
router.get('/files/:fileId/download', async (req, res) => {
  try {
    const userId = req.user.userId;
    const fileId = req.params.fileId;
    const session = sessionManager.getSession(userId);
    
    if (!session) {
      return res.status(401).json({
        success: false,
        error: 'Session not found or expired'
      });
    }
    
    logger.info('Downloading file', { userId, fileId });
    
    // Canvas file download URL
    const fileUrl = `${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}/files/${fileId}/download?download_frd=1`;
    
    try {
      const response = await fetch(fileUrl, {
        method: 'GET',
        headers: {
          'Cookie': session.cookies,
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': `${process.env.CANVAS_BASE_URL || 'https://lms.keio.jp'}/`,
        },
        redirect: 'follow',
      });
      
      if (response.status === 401) {
        sessionManager.removeSession(userId);
        return res.status(401).json({
          success: false,
          error: 'Session expired, please login again'
        });
      }
      
      if (!response.ok) {
        logger.error('File download failed', { 
          userId, 
          fileId, 
          status: response.status,
          statusText: response.statusText 
        });
        return res.status(response.status).json({
          success: false,
          error: 'Failed to download file',
          details: response.statusText
        });
      }
      
      // Forward the content type and other relevant headers
      if (response.headers.get('content-type')) {
        res.setHeader('Content-Type', response.headers.get('content-type'));
      }
      if (response.headers.get('content-length')) {
        res.setHeader('Content-Length', response.headers.get('content-length'));
      }
      if (response.headers.get('content-disposition')) {
        res.setHeader('Content-Disposition', response.headers.get('content-disposition'));
      }
      
      // Get the response as a buffer and send it
      const buffer = await response.arrayBuffer();
      res.send(Buffer.from(buffer));
      
      logger.info('File download completed', { 
        userId, 
        fileId,
        size: buffer.byteLength 
      });
      
    } catch (error) {
      logger.error('File download failed', { userId, fileId, error: error.message });
      
      return res.status(500).json({
        success: false,
        error: 'Failed to download file',
        details: error.message
      });
    }
    
  } catch (error) {
    logger.error('File download endpoint error', { error: error.message });
    
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

module.exports = router;
