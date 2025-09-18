/**
 * Subscription Metrics Monitoring
 * Real-time metrics collection and dashboard data for subscriptions
 */

const admin = require('firebase-admin');
const functions = require('firebase-functions');

// Initialize Firestore
const db = admin.firestore();

/**
 * Metrics collection intervals
 */
const METRICS_CONFIG = {
  REAL_TIME_WINDOW: 60 * 60 * 1000,      // 1 hour
  DAILY_AGGREGATION: 24 * 60 * 60 * 1000, // 24 hours
  RETENTION_DAYS: 90                      // 90 days of historical data
};

/**
 * Subscription metrics structure
 */
class SubscriptionMetrics {
  constructor() {
    this.timestamp = new Date();
    this.metrics = {
      // Real-time metrics
      activeSubscriptions: {
        total: 0,
        byTier: {
          basic: 0,
          premium: 0,
          elite: 0
        },
        byBillingPeriod: {
          monthly: 0,
          yearly: 0
        }
      },
      
      // Transaction metrics
      transactions: {
        successful: 0,
        failed: 0,
        pending: 0,
        successRate: 0
      },
      
      // Revenue metrics
      revenue: {
        daily: 0,
        monthly: 0,
        mrr: 0, // Monthly Recurring Revenue
        arr: 0, // Annual Recurring Revenue
        arpu: 0 // Average Revenue Per User
      },
      
      // Conversion metrics
      conversions: {
        trialStarts: 0,
        trialToPaid: 0,
        trialToPaidRate: 0,
        freeToTrial: 0,
        freeToTrialRate: 0
      },
      
      // Churn metrics
      churn: {
        monthly: 0,
        voluntary: 0,
        involuntary: 0,
        byTier: {
          basic: 0,
          premium: 0,
          elite: 0
        }
      },
      
      // Performance metrics
      performance: {
        validationSuccess: 0,
        validationErrors: 0,
        webhookLatency: 0,
        cacheHitRate: 0
      }
    };
  }
  
  /**
   * Calculate derived metrics
   */
  calculateDerivedMetrics() {
    // Success rate
    const totalTransactions = this.metrics.transactions.successful + this.metrics.transactions.failed;
    this.metrics.transactions.successRate = totalTransactions > 0 
      ? (this.metrics.transactions.successful / totalTransactions) * 100 
      : 0;
    
    // Trial conversion rate
    this.metrics.conversions.trialToPaidRate = this.metrics.conversions.trialStarts > 0
      ? (this.metrics.conversions.trialToPaid / this.metrics.conversions.trialStarts) * 100
      : 0;
    
    // ARPU calculation
    const totalUsers = this.metrics.activeSubscriptions.total;
    this.metrics.revenue.arpu = totalUsers > 0
      ? this.metrics.revenue.mrr / totalUsers
      : 0;
    
    // ARR from MRR
    this.metrics.revenue.arr = this.metrics.revenue.mrr * 12;
  }
}

/**
 * Collect current subscription metrics
 */
async function collectSubscriptionMetrics() {
  const metrics = new SubscriptionMetrics();
  const now = new Date();
  
  try {
    // Active subscriptions
    const activeSubsSnapshot = await db.collection('users')
      .where('subscriptionExpirationDate', '>', now)
      .get();
    
    activeSubsSnapshot.forEach(doc => {
      const user = doc.data();
      const tier = user.currentSubscriptionTier || 'none';
      const productId = user.subscriptionProductId || '';
      
      if (tier !== 'none') {
        metrics.metrics.activeSubscriptions.total++;
        metrics.metrics.activeSubscriptions.byTier[tier]++;
        
        if (productId.includes('monthly')) {
          metrics.metrics.activeSubscriptions.byBillingPeriod.monthly++;
        } else if (productId.includes('yearly')) {
          metrics.metrics.activeSubscriptions.byBillingPeriod.yearly++;
        }
      }
    });
    
    // Transaction metrics (last 24 hours)
    const dayAgo = new Date(now.getTime() - METRICS_CONFIG.DAILY_AGGREGATION);
    const transactionsSnapshot = await db.collection('subscriptionValidationLogs')
      .where('timestamp', '>', dayAgo)
      .get();
    
    transactionsSnapshot.forEach(doc => {
      const log = doc.data();
      if (log.status === 'success') {
        metrics.metrics.transactions.successful++;
      } else if (log.status === 'error') {
        metrics.metrics.transactions.failed++;
      }
    });
    
    // Revenue calculation
    metrics.metrics.revenue.mrr = calculateMRR(metrics.metrics.activeSubscriptions);
    
    // Calculate derived metrics
    metrics.calculateDerivedMetrics();
    
    return metrics;
    
  } catch (error) {
    console.error('Error collecting metrics:', error);
    throw error;
  }
}

/**
 * Calculate Monthly Recurring Revenue
 */
function calculateMRR(activeSubscriptions) {
  const pricing = {
    basic: { monthly: 4.99, yearly: 49.99 },
    premium: { monthly: 9.99, yearly: 99.99 },
    elite: { monthly: 19.99, yearly: 199.99 }
  };
  
  let mrr = 0;
  
  // Add monthly subscriptions
  Object.entries(activeSubscriptions.byTier).forEach(([tier, count]) => {
    if (pricing[tier]) {
      // Estimate 70% monthly, 30% yearly for MRR calculation
      const monthlyCount = Math.floor(count * 0.7);
      const yearlyCount = count - monthlyCount;
      
      mrr += monthlyCount * pricing[tier].monthly;
      mrr += yearlyCount * (pricing[tier].yearly / 12);
    }
  });
  
  return Math.round(mrr * 100) / 100;
}

/**
 * Store metrics snapshot
 */
async function storeMetricsSnapshot(metrics) {
  try {
    await db.collection('subscriptionMetrics').add({
      ...metrics.metrics,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      collectedAt: metrics.timestamp
    });
    
    // Store in daily aggregates
    const dateKey = metrics.timestamp.toISOString().split('T')[0];
    await db.collection('subscriptionMetricsDaily').doc(dateKey).set({
      date: dateKey,
      metrics: metrics.metrics,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    
  } catch (error) {
    console.error('Error storing metrics:', error);
    throw error;
  }
}

/**
 * Scheduled function to collect metrics every hour
 */
exports.collectSubscriptionMetricsScheduled = functions.pubsub
  .schedule('every 60 minutes')
  .onRun(async (context) => {
    console.log('📊 Collecting subscription metrics...');
    
    try {
      const metrics = await collectSubscriptionMetrics();
      await storeMetricsSnapshot(metrics);
      
      // Check for alerts
      await checkMetricAlerts(metrics);
      
      console.log('✅ Metrics collection complete', {
        activeSubscriptions: metrics.metrics.activeSubscriptions.total,
        mrr: metrics.metrics.revenue.mrr,
        successRate: metrics.metrics.transactions.successRate
      });
      
    } catch (error) {
      console.error('❌ Metrics collection failed:', error);
      await sendAlert('Metrics Collection Failed', error.message);
    }
  });

/**
 * Real-time metrics endpoint for dashboard
 */
exports.getSubscriptionMetrics = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  // TODO: Add role-based access control for metrics viewing
  
  try {
    const { timeRange = 'day', aggregate = false } = data;
    
    // Get current metrics
    const currentMetrics = await collectSubscriptionMetrics();
    
    // Get historical data based on time range
    const historicalData = await getHistoricalMetrics(timeRange);
    
    return {
      current: currentMetrics.metrics,
      historical: historicalData,
      timestamp: new Date().toISOString()
    };
    
  } catch (error) {
    console.error('Error fetching metrics:', error);
    throw new functions.https.HttpsError('internal', 'Failed to fetch metrics');
  }
});

/**
 * Get historical metrics based on time range
 */
async function getHistoricalMetrics(timeRange) {
  const now = new Date();
  let startDate;
  
  switch (timeRange) {
    case 'hour':
      startDate = new Date(now.getTime() - 60 * 60 * 1000);
      break;
    case 'day':
      startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      break;
    case 'week':
      startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      break;
    case 'month':
      startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      break;
    default:
      startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  }
  
  const snapshot = await db.collection('subscriptionMetrics')
    .where('timestamp', '>=', startDate)
    .orderBy('timestamp', 'desc')
    .limit(100)
    .get();
  
  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
}

/**
 * Check metrics for alert conditions
 */
async function checkMetricAlerts(metrics) {
  const alerts = [];
  
  // Transaction success rate alert
  if (metrics.metrics.transactions.successRate < 95) {
    alerts.push({
      type: 'ERROR',
      metric: 'Transaction Success Rate',
      value: metrics.metrics.transactions.successRate,
      threshold: 95,
      message: `Transaction success rate dropped to ${metrics.metrics.transactions.successRate.toFixed(1)}%`
    });
  }
  
  // Revenue drop alert (compare to yesterday)
  // TODO: Implement revenue comparison logic
  
  // High churn alert
  if (metrics.metrics.churn.monthly > 10) {
    alerts.push({
      type: 'WARNING',
      metric: 'Monthly Churn',
      value: metrics.metrics.churn.monthly,
      threshold: 10,
      message: `Monthly churn rate is ${metrics.metrics.churn.monthly}%`
    });
  }
  
  // Send alerts
  for (const alert of alerts) {
    await sendAlert(alert.message, alert);
  }
  
  return alerts;
}

/**
 * Send alert notification
 */
async function sendAlert(message, details) {
  // Log alert
  console.error('🚨 ALERT:', message, details);
  
  // Store alert in Firestore
  await db.collection('subscriptionAlerts').add({
    message,
    details,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    acknowledged: false
  });
  
  // Send Slack notification if configured
  const slackWebhook = functions.config().monitoring?.slack_webhook;
  if (slackWebhook) {
    // TODO: Implement Slack notification
  }
  
  // Send email if configured
  const alertEmail = functions.config().monitoring?.alert_email;
  if (alertEmail) {
    // TODO: Implement email notification
  }
}

/**
 * Dashboard configuration export
 */
exports.dashboardConfig = {
  widgets: [
    {
      id: 'active-subscriptions',
      type: 'metric',
      title: 'Active Subscriptions',
      dataKey: 'activeSubscriptions.total',
      format: 'number'
    },
    {
      id: 'mrr',
      type: 'metric',
      title: 'Monthly Recurring Revenue',
      dataKey: 'revenue.mrr',
      format: 'currency',
      prefix: '$'
    },
    {
      id: 'success-rate',
      type: 'metric',
      title: 'Transaction Success Rate',
      dataKey: 'transactions.successRate',
      format: 'percentage',
      suffix: '%'
    },
    {
      id: 'tier-distribution',
      type: 'chart',
      title: 'Subscription Tiers',
      chartType: 'donut',
      dataKey: 'activeSubscriptions.byTier'
    },
    {
      id: 'revenue-trend',
      type: 'chart',
      title: 'Revenue Trend',
      chartType: 'line',
      dataKey: 'revenue.daily',
      timeRange: 'month'
    },
    {
      id: 'conversion-funnel',
      type: 'funnel',
      title: 'Conversion Funnel',
      stages: [
        { name: 'Free Users', key: 'totalUsers' },
        { name: 'Trial Started', key: 'conversions.trialStarts' },
        { name: 'Paid Subscription', key: 'conversions.trialToPaid' }
      ]
    }
  ],
  refreshInterval: 60000, // 1 minute
  alertThresholds: {
    successRate: 95,
    monthlyChurn: 10,
    validationErrors: 5
  }
};

module.exports = {
  collectSubscriptionMetrics,
  getHistoricalMetrics,
  dashboardConfig
};