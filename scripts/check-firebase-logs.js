#!/usr/bin/env node

/**
 * Check Firebase Function Logs for Errors
 *
 * Uses Google Cloud Logging API via Application Default Credentials
 * to retrieve recent error logs from Firebase Functions.
 */

const { Logging } = require('@google-cloud/logging');

async function checkRecentErrors() {
  console.log('🔍 Checking Firebase Functions logs for errors...\n');

  const logging = new Logging({
    projectId: 'growth-training-app'
  });

  // Query for errors in the last hour
  const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

  const filter = `
    severity >= ERROR
    AND timestamp >= "${oneHourAgo.toISOString()}"
    AND (
      resource.type = "cloud_function"
      OR resource.type = "cloud_run_revision"
    )
  `;

  try {
    const [entries] = await logging.getEntries({
      filter: filter,
      pageSize: 50,
      orderBy: 'timestamp desc'
    });

    if (entries.length === 0) {
      console.log('✅ No errors found in the last hour!\n');
      return;
    }

    console.log(`⚠️  Found ${entries.length} error(s) in the last hour:\n`);

    entries.forEach((entry, index) => {
      const timestamp = entry.metadata.timestamp;
      const severity = entry.metadata.severity;
      const functionName = entry.metadata.resource?.labels?.function_name ||
                          entry.metadata.resource?.labels?.service_name ||
                          'unknown';
      const message = entry.data?.message || entry.data?.textPayload || JSON.stringify(entry.data);

      console.log(`${index + 1}. [${severity}] ${timestamp}`);
      console.log(`   Function: ${functionName}`);
      console.log(`   Message: ${message.substring(0, 200)}${message.length > 200 ? '...' : ''}`);
      console.log('');
    });

    // Summary by function
    const errorsByFunction = {};
    entries.forEach(entry => {
      const functionName = entry.metadata.resource?.labels?.function_name ||
                          entry.metadata.resource?.labels?.service_name ||
                          'unknown';
      errorsByFunction[functionName] = (errorsByFunction[functionName] || 0) + 1;
    });

    console.log('\n📊 Error Summary by Function:');
    Object.entries(errorsByFunction)
      .sort((a, b) => b[1] - a[1])
      .forEach(([func, count]) => {
        console.log(`   ${func}: ${count} error(s)`);
      });

  } catch (error) {
    console.error('❌ Error fetching logs:', error.message);
    process.exit(1);
  }
}

checkRecentErrors().catch(error => {
  console.error('❌ Script failed:', error);
  process.exit(1);
});
