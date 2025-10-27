const cron = require('node-cron');
const logger = require('../utils/logger');
const { validateSession } = require('./puppeteer-auth');

/**
 * Session Manager for handling user sessions and keep-alive
 */
class SessionManager {
  constructor() {
    this.sessions = new Map(); // userId -> session data
    this.sessionCheckInterval = parseInt(process.env.SESSION_CHECK_INTERVAL_MINUTES) || 15;
    this.sessionTimeout = parseInt(process.env.SESSION_TIMEOUT_MINUTES) || 60;
    // Keep-alive default changed to 10 minutes
    this.sessionKeepAliveInterval = parseInt(process.env.SESSION_KEEP_ALIVE_MINUTES) || 10;

    // Keep-alive behavior controls
    this.keepAliveEndpoint = process.env.KEEP_ALIVE_HTML_ENDPOINT || '/dashboard';
    this.keepAliveConcurrency = parseInt(process.env.KEEP_ALIVE_GLOBAL_CONCURRENCY) || 10;
    this.keepAliveGlobalRps = parseInt(process.env.KEEP_ALIVE_GLOBAL_RPS || '0'); // 0 = disabled
    this.keepAliveBackoffMaxMinutes = parseInt(process.env.KEEP_ALIVE_BACKOFF_MAX_MINUTES) || 60;
    this.sessionInactivityCutoffDays = parseInt(process.env.SESSION_INACTIVITY_CUTOFF_DAYS) || 5;
    this.canvasBaseUrl = process.env.CANVAS_BASE_URL || 'https://lms.keio.jp';

    // Token bucket for optional global RPS limiting
    this._bucketTokens = this.keepAliveGlobalRps > 0 ? this.keepAliveGlobalRps : 0;
    this._bucketCapacity = this.keepAliveGlobalRps > 0 ? this.keepAliveGlobalRps : 0;
    this._bucketLastRefill = Date.now();
    
    // Start session maintenance cron job
    this.startSessionMaintenance();
    
    // Start session keep-alive cron job
    this.startSessionKeepAlive();
    
    logger.info('SessionManager initialized', {
      checkInterval: this.sessionCheckInterval,
      timeout: this.sessionTimeout,
      keepAliveInterval: this.sessionKeepAliveInterval
    });
  }
  
  /**
   * Add a new session
   * @param {string} userId - User ID
   * @param {Object} sessionData - Session data
   */
  addSession(userId, sessionData) {
    const session = {
      ...sessionData,
      createdAt: new Date(),
      lastAccessed: new Date(),
      isValid: true,
      // keep-alive control state
      failureCount: 0,
      nextKeepAliveAt: new Date(0)
    };
    
    this.sessions.set(userId, session);
    logger.info('Session added', { userId, sessionCount: this.sessions.size });
  }
  
  /**
   * Get session for a user
   * @param {string} userId - User ID
   * @returns {Object|null} - Session data or null
   */
  getSession(userId) {
    const session = this.sessions.get(userId);
    if (session && session.isValid) {
      session.lastAccessed = new Date();
      return session;
    }
    return null;
  }
  
  /**
   * Remove a session
   * @param {string} userId - User ID
   */
  removeSession(userId) {
    const removed = this.sessions.delete(userId);
    if (removed) {
      logger.info('Session removed', { userId, sessionCount: this.sessions.size });
    }
  }
  
  /**
   * Check if session exists and is valid
   * @param {string} userId - User ID
   * @returns {boolean} - True if session is valid
   */
  hasValidSession(userId) {
    const session = this.sessions.get(userId);
    if (!session || !session.isValid) {
      return false;
    }
    
    // Check if session has expired
    const now = new Date();
    const timeSinceLastAccess = now - session.lastAccessed;
    const timeoutMs = this.sessionTimeout * 60 * 1000;
    
    if (timeSinceLastAccess > timeoutMs) {
      const minutesSinceLastAccess = Math.floor(timeSinceLastAccess / 60000);
      logger.warn('❌ ログインセッションが切れました（タイムアウト）', { 
        userId, 
        minutesSinceLastAccess,
        timeoutMinutes: this.sessionTimeout 
      });
      this.removeSession(userId);
      return false;
    }
    
    return true;
  }
  
  /**
   * Start session maintenance cron job
   */
  startSessionMaintenance() {
    // Run every 5 minutes (or as configured)
    const cronExpression = `*/${this.sessionCheckInterval} * * * *`;
    
    cron.schedule(cronExpression, async () => {
      await this.maintainSessions();
    });
    
    logger.info('Session maintenance cron job started', { 
      expression: cronExpression,
      interval: this.sessionCheckInterval 
    });
  }

  /**
   * Start session keep-alive cron job
   */
  startSessionKeepAlive() {
    // Run every 15 minutes (or as configured) - more frequent to prevent session timeout
    const cronExpression = `*/${this.sessionKeepAliveInterval} * * * *`;
    
    cron.schedule(cronExpression, async () => {
      await this.keepAliveSessions();
    });
    
    logger.info('Session keep-alive cron job started', { 
      expression: cronExpression,
      interval: this.sessionKeepAliveInterval 
    });
  }
  
  /**
   * Keep alive active sessions by making periodic requests to K-LMS
   */
  async keepAliveSessions() {
    try {
      logger.info('🔄 10分おきのセッションキープアライブを開始', { activeSessions: this.sessions.size });

      if (this.sessions.size === 0) {
        logger.debug('No active sessions to keep alive');
        return;
      }

      const now = new Date();
      const inactivityCutoffMs = this.sessionInactivityCutoffDays * 24 * 60 * 60 * 1000;

      let attempted = 0;
      let succeeded = 0;
      let failed = 0;
      let skipped = 0;

      const tasks = [];

      for (const [userId, session] of this.sessions) {
        try {
          if (!session.cookies || !session.isValid) {
            skipped++;
            continue;
          }

          // Remove sessions with prolonged inactivity
          if (now - session.lastAccessed > inactivityCutoffMs) {
            logger.info('Removing inactive session beyond cutoff', { userId });
            this.removeSession(userId);
            skipped++;
            continue;
          }

          // Respect per-user backoff window
          if (now < new Date(session.nextKeepAliveAt || 0)) {
            skipped++;
            continue;
          }

          const cookieString = Array.isArray(session.cookies)
            ? session.cookies.map(c => `${c.name}=${c.value}`).join('; ')
            : session.cookies;

          const url = `${this.canvasBaseUrl}${this.keepAliveEndpoint}`;
          const headers = {
            'Cookie': cookieString,
            'Accept': 'text/html',
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
          };

          attempted++;

          // Queue task with concurrency control
          tasks.push(async () => {
            try {
              // Optional RPS token acquisition before firing request
              if (this.keepAliveGlobalRps > 0) {
                await this.#acquireRpsToken();
              }
              const response = await fetch(url, {
                method: 'GET',
                headers,
                timeout: 15000
              });

              if (response.ok) {
                session.lastKeepAlive = new Date();
                session.failureCount = 0;
                session.nextKeepAliveAt = new Date(0); // reset backoff, rely on interval
                succeeded++;
                logger.info('✅ K-LMSページを再ロードしてセッションを維持しました', { userId, endpoint: this.keepAliveEndpoint, url });
              } else {
                this.#applyBackoff(session, now, response.status, userId);
                failed++;
                logger.warn('⚠️ セッションキープアライブに失敗しました', { userId, status: response.status, statusText: response.statusText });
              }
            } catch (error) {
              this.#applyBackoff(session, now, error.code || 'ERR', userId, error.message);
              failed++;
              logger.warn('⚠️ セッションキープアライブでエラーが発生しました', { userId, error: error.message });
            }
          });
        } catch (error) {
          failed++;
          logger.error('Error preparing keep-alive', { userId, error: error.message });
        }
      }

      await this.#runWithConcurrency(tasks, this.keepAliveConcurrency);

      logger.info('🔄 セッションキープアライブが完了しました', {
        totalSessions: this.sessions.size,
        attempted,
        succeeded,
        failed,
        skipped,
        nextKeepAlive: `${this.sessionKeepAliveInterval}分後`
      });
    } catch (error) {
      logger.error('Critical error in keepAliveSessions - continuing to prevent crash', {
        error: error.message,
        stack: error.stack
      });
      // Don't throw - keep server running
    }
  }

  // Private helper: apply exponential backoff to a session
  #applyBackoff(session, now, status, userId, errorMessage) {
    session.failureCount = Math.min((session.failureCount || 0) + 1, 10);
    const baseMinutes = 5; // 5,10,20,40...
    const delayMinutes = Math.min(baseMinutes * (2 ** (session.failureCount - 1)), this.keepAliveBackoffMaxMinutes);
    session.nextKeepAliveAt = new Date(now.getTime() + delayMinutes * 60 * 1000);
    logger.debug('Applied keep-alive backoff', { userId, failureCount: session.failureCount, nextKeepAliveAt: session.nextKeepAliveAt, status, error: errorMessage });
  }

  // Private helper: run async tasks with a concurrency limit
  async #runWithConcurrency(tasks, concurrency) {
    const pool = [];
    const runNext = async () => {
      const task = tasks.shift();
      if (!task) return;
      try {
        await task();
      } finally {
        await runNext();
      }
    };
    const count = Math.max(1, concurrency);
    for (let i = 0; i < count; i++) {
      pool.push(runNext());
    }
    await Promise.all(pool);
  }

  // Private helper: simple token bucket for global RPS limiting
  async #acquireRpsToken() {
    const refill = () => {
      const now = Date.now();
      const elapsed = (now - this._bucketLastRefill) / 1000; // seconds
      if (elapsed > 0 && this._bucketCapacity > 0) {
        const tokensToAdd = Math.floor(elapsed * this.keepAliveGlobalRps);
        if (tokensToAdd > 0) {
          this._bucketTokens = Math.min(this._bucketTokens + tokensToAdd, this._bucketCapacity);
          this._bucketLastRefill = now;
        }
      }
    };

    while (true) {
      refill();
      if (this._bucketTokens > 0) {
        this._bucketTokens -= 1;
        return;
      }
      // Sleep ~50ms before retry
      await this.#sleep(50);
    }
  }

  #sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Maintain active sessions by checking their validity
   */
  async maintainSessions() {
    try {
      logger.info('Starting session maintenance', { activeSessions: this.sessions.size });
      
      const sessionsToRemove = [];
      
      for (const [userId, session] of this.sessions) {
        try {
          // Check if session has expired due to timeout
          const now = new Date();
          const timeSinceLastAccess = now - session.lastAccessed;
          const timeoutMs = this.sessionTimeout * 60 * 1000;
          
          if (timeSinceLastAccess > timeoutMs) {
            const minutesSinceLastAccess = Math.floor(timeSinceLastAccess / 60000);
            logger.warn('❌ ログインセッションが切れました（タイムアウト）', { 
              userId, 
              minutesSinceLastAccess,
              timeoutMinutes: this.sessionTimeout 
            });
            sessionsToRemove.push(userId);
            continue;
          }
          
          // Validate session with K-LMS
          if (session.cookies) {
            const validation = await validateSession(session.cookies);
            
            if (validation.valid) {
              // Update user info if available
              if (validation.userInfo) {
                session.userInfo = validation.userInfo;
              }
              session.lastValidated = new Date();
              logger.debug('Session validation successful', { userId });
            } else {
              logger.warn('❌ ログインセッションが切れました（検証失敗）', { userId, error: validation.error });
              sessionsToRemove.push(userId);
            }
          } else {
            logger.warn('❌ ログインセッションが切れました（Cookieなし）', { userId });
            sessionsToRemove.push(userId);
          }
          
        } catch (error) {
          logger.error('❌ ログインセッションが切れました（エラー）', { userId, error: error.message });
          sessionsToRemove.push(userId);
        }
      }
      
      // Remove invalid sessions
      for (const userId of sessionsToRemove) {
        this.removeSession(userId);
      }
      
      if (sessionsToRemove.length > 0) {
        logger.info('Session maintenance completed', { 
          removedSessions: sessionsToRemove.length,
          activeSessions: this.sessions.size 
        });
      }
    } catch (error) {
      logger.error('Critical error in maintainSessions - continuing to prevent crash', {
        error: error.message,
        stack: error.stack
      });
      // Don't throw - keep server running
    }
  }
  
  /**
   * Get all active sessions (for debugging)
   * @returns {Array} - Array of session info
   */
  getActiveSessions() {
    const sessions = [];
    for (const [userId, session] of this.sessions) {
      sessions.push({
        userId,
        createdAt: session.createdAt,
        lastAccessed: session.lastAccessed,
        lastValidated: session.lastValidated,
        hasUserInfo: !!session.userInfo,
        hasCookies: !!session.cookies
      });
    }
    return sessions;
  }
  
  /**
   * Clean up all sessions (for shutdown)
   */
  cleanup() {
    logger.info('Cleaning up all sessions', { sessionCount: this.sessions.size });
    this.sessions.clear();
  }
}

// Create singleton instance
const sessionManager = new SessionManager();

module.exports = sessionManager;
