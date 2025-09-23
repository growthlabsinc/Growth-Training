#!/usr/bin/env node

import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { program } from 'commander';
import chalk from 'chalk';

// Firebase Configuration
const PROJECT_ID = 'growth-training-app';
const COLLECTION_NAME = 'ai_coach_knowledge';
const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.join(path.dirname(new URL(import.meta.url).pathname), '..', 'service-account-key.json');

// Initialize Firebase Admin
function initializeFirebase() {
  if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
    console.error(chalk.red(`❌ Service account key not found at: ${SERVICE_ACCOUNT_PATH}`));
    console.error(chalk.yellow('Please ensure you have a service account key file.'));
    console.error(chalk.yellow('Download from Firebase Console > Project Settings > Service Accounts'));
    process.exit(1);
  }

  try {
    const serviceAccount = JSON.parse(fs.readFileSync(SERVICE_ACCOUNT_PATH, 'utf8'));

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: PROJECT_ID
    });

    console.log(chalk.green(`✅ Firebase Admin initialized for project: ${PROJECT_ID}`));
    return admin.firestore();
  } catch (error) {
    console.error(chalk.red('❌ Failed to initialize Firebase Admin:'), error.message);
    process.exit(1);
  }
}

// Generate comprehensive statistics
async function generateStatistics(db) {
  const snapshot = await db.collection(COLLECTION_NAME).get();
  
  const stats = {
    totalDocuments: 0,
    byCategory: {},
    byPriority: {},
    byDeploymentScript: {},
    contentMetrics: {
      totalCharacters: 0,
      averageContentLength: 0,
      shortestContent: Infinity,
      longestContent: 0,
      totalKeywords: 0,
      averageKeywords: 0,
      uniqueKeywords: new Set()
    },
    versions: {
      current: {},
      outdated: 0
    },
    timestamps: {
      oldest: null,
      newest: null,
      lastDay: 0,
      lastWeek: 0,
      lastMonth: 0
    },
    quality: {
      withSafetyWarnings: 0,
      withMedicalDisclaimer: 0,
      highPriority: 0,
      missingFields: 0
    }
  };

  const now = new Date();
  const dayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

  snapshot.forEach(doc => {
    const data = doc.data();
    stats.totalDocuments++;

    // Category stats
    stats.byCategory[data.category] = (stats.byCategory[data.category] || 0) + 1;

    // Priority stats
    stats.byPriority[data.priority] = (stats.byPriority[data.priority] || 0) + 1;

    // Deployment script stats
    if (data.deployedBy) {
      stats.byDeploymentScript[data.deployedBy] = (stats.byDeploymentScript[data.deployedBy] || 0) + 1;
    }

    // Content metrics
    if (data.content) {
      const contentLength = data.content.length;
      stats.contentMetrics.totalCharacters += contentLength;
      stats.contentMetrics.shortestContent = Math.min(stats.contentMetrics.shortestContent, contentLength);
      stats.contentMetrics.longestContent = Math.max(stats.contentMetrics.longestContent, contentLength);
    }

    // Keyword metrics
    if (data.keywords && Array.isArray(data.keywords)) {
      stats.contentMetrics.totalKeywords += data.keywords.length;
      data.keywords.forEach(keyword => {
        stats.contentMetrics.uniqueKeywords.add(keyword.toLowerCase());
      });
    }

    // Version tracking
    const version = data.version || 1;
    stats.versions.current[version] = (stats.versions.current[version] || 0) + 1;
    if (version > 1) stats.versions.outdated++;

    // Timestamp analysis
    if (data.updatedAt) {
      const updateTime = data.updatedAt.toDate ? data.updatedAt.toDate() : new Date(data.updatedAt);
      
      if (!stats.timestamps.oldest || updateTime < stats.timestamps.oldest) {
        stats.timestamps.oldest = updateTime;
      }
      if (!stats.timestamps.newest || updateTime > stats.timestamps.newest) {
        stats.timestamps.newest = updateTime;
      }

      if (updateTime > dayAgo) stats.timestamps.lastDay++;
      if (updateTime > weekAgo) stats.timestamps.lastWeek++;
      if (updateTime > monthAgo) stats.timestamps.lastMonth++;
    }

    // Quality metrics
    const contentLower = (data.content || '').toLowerCase();
    if (contentLower.includes('warning') || contentLower.includes('caution') || contentLower.includes('safety')) {
      stats.quality.withSafetyWarnings++;
    }
    if (contentLower.includes('medical') || contentLower.includes('physician') || contentLower.includes('doctor')) {
      stats.quality.withMedicalDisclaimer++;
    }
    if (data.priority >= 8) {
      stats.quality.highPriority++;
    }

    // Check for missing fields
    const requiredFields = ['title', 'content', 'category', 'keywords', 'priority'];
    const missingFields = requiredFields.filter(field => !data[field]);
    if (missingFields.length > 0) {
      stats.quality.missingFields++;
    }
  });

  // Calculate averages
  if (stats.totalDocuments > 0) {
    stats.contentMetrics.averageContentLength = Math.round(stats.contentMetrics.totalCharacters / stats.totalDocuments);
    stats.contentMetrics.averageKeywords = Math.round(stats.contentMetrics.totalKeywords / stats.totalDocuments);
  }

  // Convert Set to count
  stats.contentMetrics.uniqueKeywordsCount = stats.contentMetrics.uniqueKeywords.size;
  delete stats.contentMetrics.uniqueKeywords;

  return stats;
}

// Display statistics in formatted output
function displayStatistics(stats) {
  console.log(chalk.blue('\n📊 Knowledge Base Statistics Report\n'));
  console.log(chalk.gray('═'.repeat(60)));

  // Overview
  console.log(chalk.cyan('\n📈 OVERVIEW'));
  console.log(chalk.white(`   Total Documents: ${chalk.bold(stats.totalDocuments)}`));
  console.log(chalk.white(`   Unique Keywords: ${chalk.bold(stats.contentMetrics.uniqueKeywordsCount)}`));
  console.log(chalk.white(`   Average Content Length: ${chalk.bold(stats.contentMetrics.averageContentLength)} chars`));
  console.log(chalk.white(`   Average Keywords per Doc: ${chalk.bold(stats.contentMetrics.averageKeywords)}`));

  // Category Distribution
  console.log(chalk.cyan('\n📂 CATEGORY DISTRIBUTION'));
  const sortedCategories = Object.entries(stats.byCategory).sort((a, b) => b[1] - a[1]);
  sortedCategories.forEach(([category, count]) => {
    const percentage = ((count / stats.totalDocuments) * 100).toFixed(1);
    const bar = '█'.repeat(Math.round(count / 2));
    console.log(chalk.white(`   ${category.padEnd(15)} ${count.toString().padStart(4)} (${percentage}%) ${chalk.gray(bar)}`));
  });

  // Priority Distribution
  console.log(chalk.cyan('\n⭐ PRIORITY DISTRIBUTION'));
  for (let i = 10; i >= 1; i--) {
    if (stats.byPriority[i]) {
      const percentage = ((stats.byPriority[i] / stats.totalDocuments) * 100).toFixed(1);
      const bar = '█'.repeat(Math.round(stats.byPriority[i] / 2));
      const color = i >= 8 ? chalk.red : i >= 5 ? chalk.yellow : chalk.green;
      console.log(color(`   Priority ${i.toString().padStart(2)}: ${stats.byPriority[i].toString().padStart(4)} (${percentage}%) ${chalk.gray(bar)}`));
    }
  }

  // Content Metrics
  console.log(chalk.cyan('\n📝 CONTENT METRICS'));
  console.log(chalk.white(`   Shortest Document: ${chalk.bold(stats.contentMetrics.shortestContent)} chars`));
  console.log(chalk.white(`   Longest Document: ${chalk.bold(stats.contentMetrics.longestContent)} chars`));
  console.log(chalk.white(`   Total Content: ${chalk.bold((stats.contentMetrics.totalCharacters / 1000).toFixed(1))}k chars`));

  // Quality Indicators
  console.log(chalk.cyan('\n✅ QUALITY INDICATORS'));
  const safetyPercentage = ((stats.quality.withSafetyWarnings / stats.totalDocuments) * 100).toFixed(1);
  const disclaimerPercentage = ((stats.quality.withMedicalDisclaimer / stats.totalDocuments) * 100).toFixed(1);
  const highPriorityPercentage = ((stats.quality.highPriority / stats.totalDocuments) * 100).toFixed(1);
  
  console.log(chalk.white(`   With Safety Warnings: ${stats.quality.withSafetyWarnings} (${safetyPercentage}%)`));
  console.log(chalk.white(`   With Medical Disclaimer: ${stats.quality.withMedicalDisclaimer} (${disclaimerPercentage}%)`));
  console.log(chalk.white(`   High Priority (≥8): ${stats.quality.highPriority} (${highPriorityPercentage}%)`));
  if (stats.quality.missingFields > 0) {
    console.log(chalk.red(`   Missing Required Fields: ${stats.quality.missingFields}`));
  }

  // Version Information
  console.log(chalk.cyan('\n🔢 VERSION INFORMATION'));
  Object.entries(stats.versions.current).sort((a, b) => parseInt(a[0]) - parseInt(b[0])).forEach(([version, count]) => {
    console.log(chalk.white(`   Version ${version}: ${count} documents`));
  });
  if (stats.versions.outdated > 0) {
    console.log(chalk.yellow(`   Documents with updates: ${stats.versions.outdated}`));
  }

  // Deployment Sources
  if (Object.keys(stats.byDeploymentScript).length > 0) {
    console.log(chalk.cyan('\n🚀 DEPLOYMENT SOURCES'));
    Object.entries(stats.byDeploymentScript).sort((a, b) => b[1] - a[1]).forEach(([script, count]) => {
      console.log(chalk.white(`   ${script}: ${count} documents`));
    });
  }

  // Recent Activity
  console.log(chalk.cyan('\n🕐 RECENT ACTIVITY'));
  console.log(chalk.white(`   Updated in last 24 hours: ${stats.timestamps.lastDay}`));
  console.log(chalk.white(`   Updated in last 7 days: ${stats.timestamps.lastWeek}`));
  console.log(chalk.white(`   Updated in last 30 days: ${stats.timestamps.lastMonth}`));
  if (stats.timestamps.oldest) {
    console.log(chalk.gray(`   Oldest update: ${stats.timestamps.oldest.toISOString().split('T')[0]}`));
  }
  if (stats.timestamps.newest) {
    console.log(chalk.gray(`   Newest update: ${stats.timestamps.newest.toISOString().split('T')[0]}`));
  }

  console.log(chalk.gray('\n' + '═'.repeat(60)));
}

// Export statistics to file
async function exportStatistics(stats, format = 'json') {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19);
  const filename = `knowledge-stats-${timestamp}.${format}`;
  const filepath = path.join(path.dirname(new URL(import.meta.url).pathname), '..', 'reports', filename);
  
  // Ensure reports directory exists
  const reportsDir = path.dirname(filepath);
  if (!fs.existsSync(reportsDir)) {
    fs.mkdirSync(reportsDir, { recursive: true });
  }

  if (format === 'json') {
    fs.writeFileSync(filepath, JSON.stringify(stats, null, 2));
  } else if (format === 'csv') {
    // Create CSV format
    let csv = 'Metric,Value\n';
    csv += `Total Documents,${stats.totalDocuments}\n`;
    csv += `Unique Keywords,${stats.contentMetrics.uniqueKeywordsCount}\n`;
    csv += `Average Content Length,${stats.contentMetrics.averageContentLength}\n`;
    
    // Add categories
    csv += '\nCategory,Count\n';
    Object.entries(stats.byCategory).forEach(([cat, count]) => {
      csv += `${cat},${count}\n`;
    });
    
    fs.writeFileSync(filepath, csv);
  }

  console.log(chalk.green(`\n📄 Statistics exported to: ${filepath}`));
  return filepath;
}

// Compare statistics between two time periods
async function compareStatistics(db, days = 7) {
  console.log(chalk.blue(`\n📊 Comparing statistics over ${days} days\n`));
  
  const now = new Date();
  const pastDate = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
  
  // Get current stats
  const currentStats = await generateStatistics(db);
  
  // Get documents from past period
  const pastSnapshot = await db.collection(COLLECTION_NAME)
    .where('updatedAt', '<=', pastDate)
    .get();
  
  console.log(chalk.cyan('Growth Metrics:'));
  console.log(chalk.white(`   Documents ${days} days ago: ${pastSnapshot.size}`));
  console.log(chalk.white(`   Documents now: ${currentStats.totalDocuments}`));
  console.log(chalk.green(`   Growth: +${currentStats.totalDocuments - pastSnapshot.size} documents`));
  
  const growthRate = ((currentStats.totalDocuments - pastSnapshot.size) / pastSnapshot.size * 100).toFixed(1);
  console.log(chalk.green(`   Growth Rate: ${growthRate}%`));
}

// Main function
async function main(options) {
  console.log(chalk.blue('\n📊 Knowledge Base Statistics Reporter\n'));

  const db = initializeFirebase();

  // Generate statistics
  const stats = await generateStatistics(db);

  // Display statistics
  if (!options.quiet) {
    displayStatistics(stats);
  }

  // Export if requested
  if (options.export) {
    await exportStatistics(stats, options.export);
  }

  // Compare if requested
  if (options.compare) {
    await compareStatistics(db, parseInt(options.compare));
  }

  // Return stats for programmatic use
  if (options.json) {
    console.log(JSON.stringify(stats, null, 2));
  }

  return stats;
}

// CLI setup
program
  .name('knowledgeStatsReporter')
  .description('Generate comprehensive statistics for the knowledge base')
  .version('1.0.0');

program
  .option('-e, --export <format>', 'Export statistics to file (json or csv)')
  .option('-c, --compare <days>', 'Compare statistics over time period')
  .option('-q, --quiet', 'Suppress console output')
  .option('-j, --json', 'Output raw JSON statistics')
  .action((options) => {
    main(options);
  });

program.parse();