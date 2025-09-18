/**
 * Enhanced Firebase Logger for debugging Live Activities and StoreKit
 */

const { logger } = require('firebase-functions');

class EnhancedLogger {
  constructor(functionName) {
    this.functionName = functionName;
    this.requestId = null;
  }

  /**
   * Generate a unique request ID for tracking
   */
  generateRequestId() {
    this.requestId = Date.now().toString(36) + Math.random().toString(36).substr(2);
    return this.requestId;
  }

  /**
   * Format log message with metadata
   */
  formatMessage(level, message, data = {}) {
    const timestamp = new Date().toISOString();
    const logData = {
      timestamp,
      functionName: this.functionName,
      requestId: this.requestId,
      level,
      message,
      ...data
    };

    // Add performance metrics if available
    if (global.gc) {
      const memUsage = process.memoryUsage();
      logData.memory = {
        heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024) + 'MB',
        heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024) + 'MB',
        rss: Math.round(memUsage.rss / 1024 / 1024) + 'MB'
      };
    }

    return logData;
  }

  /**
   * Log a debug message
   */
  debug(message, data = {}) {
    logger.debug(this.formatMessage('DEBUG', message, data));
  }

  /**
   * Log an info message
   */
  info(message, data = {}) {
    logger.info(this.formatMessage('INFO', message, data));
  }

  /**
   * Log a warning message
   */
  warn(message, data = {}) {
    logger.warn(this.formatMessage('WARN', message, data));
  }

  /**
   * Log an error message
   */
  error(message, error = null, data = {}) {
    const errorData = {
      ...data,
      error: error ? {
        message: error.message,
        stack: error.stack,
        code: error.code,
        details: error.details
      } : null
    };
    logger.error(this.formatMessage('ERROR', message, errorData));
  }

  /**
   * Log a success message
   */
  success(message, data = {}) {
    logger.info(this.formatMessage('SUCCESS', `✅ ${message}`, data));
  }

  /**
   * Log Live Activity specific data
   */
  logLiveActivity(action, data) {
    const liveActivityData = {
      action,
      activityId: data.activityId,
      pushToken: data.pushToken ? {
        exists: true,
        length: data.pushToken.length,
        prefix: data.pushToken.substring(0, 10) + '...'
      } : null,
      contentState: data.contentState ? {
        event: data.contentState.event,
        sessionType: data.contentState.sessionType,
        methodName: data.contentState.methodName,
        duration: data.contentState.duration,
        startedAt: data.contentState.startedAt,
        pausedAt: data.contentState.pausedAt,
        isPaused: data.contentState.isPaused,
        elapsed: data.contentState.elapsed,
        timestamp: data.contentState.timestamp
      } : null,
      apnsResponse: data.apnsResponse,
      environment: data.environment,
      dismissalDate: data.dismissalDate
    };

    this.info(`🎯 Live Activity ${action}`, liveActivityData);
  }

  /**
   * Log StoreKit/Subscription specific data
   */
  logStoreKit(action, data) {
    const storeKitData = {
      action,
      receiptData: data.receiptData ? {
        exists: true,
        length: data.receiptData.length,
        prefix: data.receiptData.substring(0, 20) + '...'
      } : null,
      transactionId: data.transactionId,
      originalTransactionId: data.originalTransactionId,
      productId: data.productId,
      purchaseDate: data.purchaseDate,
      expirationDate: data.expirationDate,
      subscriptionStatus: data.subscriptionStatus,
      environment: data.environment,
      bundleId: data.bundleId,
      appAccountToken: data.appAccountToken,
      notificationType: data.notificationType,
      subtype: data.subtype
    };

    this.info(`💳 StoreKit ${action}`, storeKitData);
  }

  /**
   * Log APNS request/response
   */
  logAPNS(action, data) {
    const apnsData = {
      action,
      host: data.host,
      method: data.method,
      statusCode: data.statusCode,
      headers: data.headers,
      responseTime: data.responseTime,
      error: data.error,
      pushToken: data.pushToken ? {
        exists: true,
        length: data.pushToken.length,
        prefix: data.pushToken.substring(0, 10) + '...'
      } : null,
      payloadSize: data.payloadSize,
      priority: data.priority,
      topic: data.topic,
      environment: data.environment
    };

    if (data.error) {
      this.error(`🚫 APNS ${action} Failed`, null, apnsData);
    } else {
      this.info(`📤 APNS ${action}`, apnsData);
    }
  }

  /**
   * Log performance metrics
   */
  logPerformance(operation, startTime, data = {}) {
    const duration = Date.now() - startTime;
    const perfData = {
      operation,
      duration: `${duration}ms`,
      ...data
    };

    if (duration > 5000) {
      this.warn(`⚠️ Slow operation: ${operation}`, perfData);
    } else {
      this.debug(`⏱️ Performance: ${operation}`, perfData);
    }
  }

  /**
   * Log user context
   */
  logUserContext(request) {
    const userContext = {
      userId: request.auth?.uid || 'anonymous',
      isAuthenticated: !!request.auth,
      userAgent: request.rawRequest?.headers['user-agent'] || 'unknown',
      sourceIP: request.rawRequest?.ip || 'unknown',
      appVersion: request.data?.appVersion || 'unknown',
      platform: request.data?.platform || 'unknown',
      deviceId: request.data?.deviceId || 'unknown'
    };

    this.debug('👤 User Context', userContext);
  }

  /**
   * Start a new request log session
   */
  startRequest(functionName, request) {
    this.generateRequestId();
    this.info(`🚀 === ${functionName.toUpperCase()} REQUEST START ===`);
    this.logUserContext(request);
    return this.requestId;
  }

  /**
   * End a request log session
   */
  endRequest(success = true, data = {}) {
    if (success) {
      this.success(`=== REQUEST END (${this.requestId}) ===`, data);
    } else {
      this.error(`=== REQUEST FAILED (${this.requestId}) ===`, null, data);
    }
  }
}

module.exports = EnhancedLogger;