#!/usr/bin/env node
/**
 * Citation Verification Script
 *
 * Verifies all citations from educational articles by:
 * - Checking DOI resolution
 * - Validating PubMed IDs
 * - Detecting retracted papers
 * - Generating verification reports
 * - Updating Firestore with verification status
 *
 * Usage: node scripts/verify-citations.js
 */

const admin = require('firebase-admin');
const fetch = require('node-fetch');
const fs = require('fs').promises;
const path = require('path');

// Initialize Firebase Admin SDK
let db;

function initializeFirebase() {
  if (admin.apps.length === 0) {
    // Use Application Default Credentials (set via GOOGLE_APPLICATION_CREDENTIALS env var)
    // or service account key file
    try {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
        projectId: 'growth-training-app'
      });
    } catch (error) {
      console.log('Falling back to explicit service account initialization...');
      // Fallback: check for service account file
      const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS ||
        path.join(__dirname, '../service-account-key.json');

      if (require('fs').existsSync(serviceAccountPath)) {
        const serviceAccount = require(serviceAccountPath);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount)
        });
      } else {
        throw new Error('Firebase credentials not found. Set GOOGLE_APPLICATION_CREDENTIALS or provide service-account-key.json');
      }
    }
  }
  db = admin.firestore();
  console.log('✅ Firebase Admin SDK initialized');
}

// Rate limiting helper
function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Verify DOI resolution
 * @param {string} doi - DOI identifier
 * @returns {Promise<{valid: boolean, status: number, resolvedUrl: string, error?: string}>}
 */
async function verifyDOI(doi) {
  if (!doi) return { valid: false, status: 0, resolvedUrl: '', error: 'No DOI provided' };

  try {
    const url = `https://doi.org/${doi}`;
    const response = await fetch(url, {
      method: 'HEAD',
      redirect: 'follow',
      timeout: 10000 // 10 second timeout
    });

    return {
      valid: response.ok,
      status: response.status,
      resolvedUrl: response.url
    };
  } catch (error) {
    return {
      valid: false,
      status: 0,
      resolvedUrl: '',
      error: error.message
    };
  }
}

/**
 * Verify PubMed ID and check retraction status
 * @param {string} pmid - PubMed ID
 * @returns {Promise<{valid: boolean, status: string, retracted: boolean, error?: string}>}
 */
async function verifyPMID(pmid) {
  if (!pmid) return { valid: false, status: 'unknown', retracted: false, error: 'No PMID provided' };

  try {
    const url = `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id=${pmid}&retmode=json`;
    const response = await fetch(url, { timeout: 10000 });
    const data = await response.json();

    // Check if error in response
    if (data.error) {
      return {
        valid: false,
        status: 'error',
        retracted: false,
        error: data.error
      };
    }

    // Check if result exists for this PMID
    const result = data.result?.[pmid];
    if (!result) {
      return {
        valid: false,
        status: 'not_found',
        retracted: false,
        error: 'PMID not found in PubMed database'
      };
    }

    // Check retraction status
    const pubStatus = result.pubstatus || 'unknown';
    const attributes = result.attributes || [];
    const isRetracted = attributes.some(attr =>
      attr.toLowerCase().includes('retracted') ||
      attr.toLowerCase().includes('withdrawn')
    );

    // Also check publication types for retraction
    const pubTypes = result.pubtype || [];
    const hasRetractionType = pubTypes.some(type =>
      type.toLowerCase().includes('retraction')
    );

    return {
      valid: true,
      status: pubStatus,
      retracted: isRetracted || hasRetractionType
    };
  } catch (error) {
    return {
      valid: false,
      status: 'error',
      retracted: false,
      error: error.message
    };
  }
}

/**
 * Verify general URL
 * @param {string} url - URL to verify
 * @returns {Promise<{valid: boolean, status: number, error?: string}>}
 */
async function verifyURL(url) {
  if (!url) return { valid: false, status: 0, error: 'No URL provided' };

  try {
    const response = await fetch(url, {
      method: 'HEAD',
      redirect: 'follow',
      timeout: 10000
    });

    return {
      valid: response.ok,
      status: response.status
    };
  } catch (error) {
    return {
      valid: false,
      status: 0,
      error: error.message
    };
  }
}

/**
 * Load all educational resources from Firestore
 * @returns {Promise<Array>}
 */
async function loadEducationalResources() {
  console.log('📚 Loading educational resources from Firestore...');

  try {
    const snapshot = await db.collection('educational_resources').get();
    const resources = [];

    snapshot.forEach(doc => {
      resources.push({
        id: doc.id,
        ...doc.data()
      });
    });

    console.log(`✅ Loaded ${resources.length} educational resources`);
    return resources;
  } catch (error) {
    console.error('❌ Error loading educational resources:', error);
    throw error;
  }
}

/**
 * Extract all citations from articles
 * @param {Array} resources - Array of educational resource documents
 * @returns {Array} - Array of citations with article context
 */
function extractCitations(resources) {
  console.log('📋 Extracting citations from articles...');

  const allCitations = [];

  for (const resource of resources) {
    const citations = resource.citations || [];

    for (const citation of citations) {
      allCitations.push({
        articleId: resource.id,
        articleTitle: resource.title || 'Unknown',
        citation: citation
      });
    }
  }

  console.log(`✅ Extracted ${allCitations.length} citations from ${resources.length} articles`);
  return allCitations;
}

/**
 * Verify all citations with rate limiting
 * @param {Array} citations - Array of citations to verify
 * @returns {Promise<Array>} - Array of verification results
 */
async function verifyCitations(citations) {
  console.log('🔍 Starting citation verification...');
  console.log('⏱️  Rate limiting: 1 req/sec for DOI, 3 req/sec for PubMed');

  const results = [];
  let doiCount = 0;
  let pmidCount = 0;
  let urlCount = 0;

  for (let i = 0; i < citations.length; i++) {
    const { articleId, articleTitle, citation } = citations[i];

    console.log(`\n[${i + 1}/${citations.length}] Verifying citation: ${citation.id}`);
    console.log(`   Article: ${articleTitle}`);

    const result = {
      articleId,
      articleTitle,
      citationId: citation.id,
      citation: {
        authors: citation.authors,
        year: citation.year,
        title: citation.title,
        journal: citation.journal
      },
      doi: citation.doi || null,
      pmid: citation.pmid || null,
      url: citation.url || null,
      verification: {
        timestamp: new Date().toISOString(),
        doiStatus: null,
        pmidStatus: null,
        urlStatus: null,
        isValid: true,
        hasIssues: false,
        issues: []
      }
    };

    // Verify DOI if present
    if (citation.doi) {
      console.log(`   Checking DOI: ${citation.doi}`);
      const doiResult = await verifyDOI(citation.doi);
      result.verification.doiStatus = doiResult;
      doiCount++;

      if (!doiResult.valid) {
        result.verification.hasIssues = true;
        result.verification.issues.push(`DOI verification failed: ${doiResult.error || `HTTP ${doiResult.status}`}`);
      }

      // Rate limit: 1 request per second for DOI
      await delay(1000);
    }

    // Verify PMID if present
    if (citation.pmid) {
      console.log(`   Checking PMID: ${citation.pmid}`);
      const pmidResult = await verifyPMID(citation.pmid);
      result.verification.pmidStatus = pmidResult;
      pmidCount++;

      if (!pmidResult.valid) {
        result.verification.hasIssues = true;
        result.verification.issues.push(`PMID verification failed: ${pmidResult.error || 'Unknown error'}`);
      }

      if (pmidResult.retracted) {
        result.verification.hasIssues = true;
        result.verification.isValid = false;
        result.verification.issues.push('⚠️  RETRACTED PAPER DETECTED');
      }

      // Rate limit: 3 requests per second for PubMed (333ms delay)
      await delay(333);
    }

    // Verify URL if present and no DOI/PMID
    if (citation.url && !citation.doi && !citation.pmid) {
      console.log(`   Checking URL: ${citation.url}`);
      const urlResult = await verifyURL(citation.url);
      result.verification.urlStatus = urlResult;
      urlCount++;

      if (!urlResult.valid) {
        result.verification.hasIssues = true;
        result.verification.issues.push(`URL verification failed: ${urlResult.error || `HTTP ${urlResult.status}`}`);
      }

      await delay(1000);
    }

    results.push(result);

    // Log status
    if (result.verification.hasIssues) {
      console.log(`   ⚠️  Issues found: ${result.verification.issues.join(', ')}`);
    } else {
      console.log(`   ✅ Verified successfully`);
    }
  }

  console.log(`\n✅ Verification complete!`);
  console.log(`   DOI checks: ${doiCount}`);
  console.log(`   PMID checks: ${pmidCount}`);
  console.log(`   URL checks: ${urlCount}`);

  return results;
}

/**
 * Generate verification report
 * @param {Array} results - Array of verification results
 * @returns {Object} - Formatted report object
 */
function generateReport(results) {
  console.log('\n📊 Generating verification report...');

  const timestamp = new Date().toISOString();
  const totalCitations = results.length;
  const verifiedCitations = results.filter(r => !r.verification.hasIssues);
  const brokenCitations = results.filter(r => r.verification.hasIssues && r.verification.isValid);
  const retractedCitations = results.filter(r => !r.verification.isValid);

  const report = {
    verification_date: timestamp,
    total_citations: totalCitations,
    verified_count: verifiedCitations.length,
    broken_count: brokenCitations.length,
    warning_count: retractedCitations.length,
    details: results.map(r => ({
      article_id: r.articleId,
      article_title: r.articleTitle,
      citation_id: r.citationId,
      citation_title: r.citation.title,
      doi: r.doi,
      doi_status: r.verification.doiStatus?.valid ? 'valid' : (r.doi ? 'invalid' : null),
      pmid: r.pmid,
      pmid_status: r.verification.pmidStatus?.valid ? 'valid' : (r.pmid ? 'invalid' : null),
      retracted: r.verification.pmidStatus?.retracted || false,
      url: r.url,
      url_status: r.verification.urlStatus?.valid ? 'valid' : (r.url ? 'invalid' : null),
      has_issues: r.verification.hasIssues,
      issues: r.verification.issues,
      last_checked: r.verification.timestamp
    })),
    broken_citations: brokenCitations.map(r => ({
      article_id: r.articleId,
      article_title: r.articleTitle,
      citation_id: r.citationId,
      citation_title: r.citation.title,
      doi: r.doi,
      pmid: r.pmid,
      url: r.url,
      error: r.verification.issues.join('; ')
    })),
    retracted_papers: retractedCitations.map(r => ({
      article_id: r.articleId,
      article_title: r.articleTitle,
      citation_id: r.citationId,
      citation_title: r.citation.title,
      pmid: r.pmid,
      details: r.verification.issues.join('; ')
    }))
  };

  console.log('✅ Report generated');
  return report;
}

/**
 * Save report to JSON file
 * @param {Object} report - Report object
 * @returns {Promise<string>} - Path to saved report
 */
async function saveReportJSON(report) {
  const dateStr = new Date().toISOString().split('T')[0];
  const filename = `citation-verification-report-${dateStr}.json`;
  const filepath = path.join(__dirname, '../docs/operations', filename);

  console.log(`💾 Saving JSON report to: ${filepath}`);

  try {
    await fs.writeFile(filepath, JSON.stringify(report, null, 2), 'utf8');
    console.log('✅ JSON report saved');
    return filepath;
  } catch (error) {
    console.error('❌ Error saving JSON report:', error);
    throw error;
  }
}

/**
 * Generate human-readable markdown summary
 * @param {Object} report - Report object
 * @returns {string} - Markdown formatted summary
 */
function generateMarkdownSummary(report) {
  const date = new Date(report.verification_date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });

  let markdown = `# Citation Verification Report\n\n`;
  markdown += `**Date**: ${date}\n\n`;
  markdown += `## Summary\n\n`;
  markdown += `- **Total Citations**: ${report.total_citations}\n`;
  markdown += `- **Verified**: ${report.verified_count} ✅\n`;
  markdown += `- **Broken/Issues**: ${report.broken_count} ⚠️\n`;
  markdown += `- **Retracted Papers**: ${report.warning_count} ❌\n\n`;

  if (report.retracted_papers.length > 0) {
    markdown += `## 🚨 Retracted Papers (Action Required)\n\n`;
    for (const paper of report.retracted_papers) {
      markdown += `### ${paper.citation_title}\n\n`;
      markdown += `- **Article**: ${paper.article_title}\n`;
      markdown += `- **Citation ID**: \`${paper.citation_id}\`\n`;
      markdown += `- **PMID**: ${paper.pmid}\n`;
      markdown += `- **Details**: ${paper.details}\n\n`;
      markdown += `**Action**: Remove this citation and find alternative source\n\n`;
    }
  }

  if (report.broken_citations.length > 0) {
    markdown += `## ⚠️  Broken Citations\n\n`;
    for (const citation of report.broken_citations) {
      markdown += `### ${citation.citation_title}\n\n`;
      markdown += `- **Article**: ${citation.article_title}\n`;
      markdown += `- **Citation ID**: \`${citation.citation_id}\`\n`;
      if (citation.doi) markdown += `- **DOI**: ${citation.doi}\n`;
      if (citation.pmid) markdown += `- **PMID**: ${citation.pmid}\n`;
      if (citation.url) markdown += `- **URL**: ${citation.url}\n`;
      markdown += `- **Error**: ${citation.error}\n\n`;
    }
  }

  if (report.verified_count === report.total_citations) {
    markdown += `## ✅ All Citations Verified\n\n`;
    markdown += `All ${report.total_citations} citations have been successfully verified. No action required.\n\n`;
  }

  markdown += `## Verification Details\n\n`;
  markdown += `See full JSON report for detailed verification data.\n\n`;

  return markdown;
}

/**
 * Save markdown summary to file
 * @param {Object} report - Report object
 * @returns {Promise<string>} - Path to saved markdown file
 */
async function saveReportMarkdown(report) {
  const dateStr = new Date().toISOString().split('T')[0];
  const filename = `citation-verification-summary-${dateStr}.md`;
  const filepath = path.join(__dirname, '../docs/operations', filename);

  console.log(`💾 Saving markdown summary to: ${filepath}`);

  const markdown = generateMarkdownSummary(report);

  try {
    await fs.writeFile(filepath, markdown, 'utf8');
    console.log('✅ Markdown summary saved');
    return filepath;
  } catch (error) {
    console.error('❌ Error saving markdown summary:', error);
    throw error;
  }
}

/**
 * Find alternative source for a broken citation
 * @param {Object} citation - Citation object with doi, pmid, title, authors
 * @returns {Promise<Object>} - Alternative source suggestions
 */
async function findAlternativeSource(citation) {
  console.log(`🔍 Searching for alternative source for: ${citation.title}`);

  const alternatives = {
    citationId: citation.id,
    citationTitle: citation.title,
    originalDOI: citation.doi || null,
    originalPMID: citation.pmid || null,
    suggestions: []
  };

  try {
    // Search CrossRef API for DOI changes
    if (citation.doi) {
      console.log(`   Checking CrossRef for DOI updates...`);
      try {
        // CrossRef API search by DOI
        const crossrefUrl = `https://api.crossref.org/works/${encodeURIComponent(citation.doi)}`;
        const response = await fetch(crossrefUrl, { timeout: 10000 });

        if (response.ok) {
          const data = await response.json();
          const work = data.message;

          // Check if DOI has been updated/redirected
          if (work.DOI && work.DOI !== citation.doi) {
            alternatives.suggestions.push({
              source: 'CrossRef',
              type: 'updated_doi',
              newDOI: work.DOI,
              url: `https://doi.org/${work.DOI}`,
              confidence: 'high'
            });
          }

          // Check for alternative URLs
          if (work.URL && work.URL !== `https://doi.org/${citation.doi}`) {
            alternatives.suggestions.push({
              source: 'CrossRef',
              type: 'alternative_url',
              url: work.URL,
              confidence: 'medium'
            });
          }
        }
      } catch (error) {
        console.log(`   CrossRef search failed: ${error.message}`);
      }

      await delay(1000); // Rate limiting
    }

    // Search PubMed Central for archived versions
    if (citation.pmid) {
      console.log(`   Checking PubMed Central for archived versions...`);
      try {
        const pmcUrl = `https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/?ids=${citation.pmid}&format=json`;
        const response = await fetch(pmcUrl, { timeout: 10000 });

        if (response.ok) {
          const data = await response.json();
          const records = data.records;

          if (records && records.length > 0) {
            const record = records[0];

            // Check if PMC version available
            if (record.pmcid) {
              alternatives.suggestions.push({
                source: 'PubMed Central',
                type: 'pmc_archive',
                pmcid: record.pmcid,
                url: `https://www.ncbi.nlm.nih.gov/pmc/articles/${record.pmcid}/`,
                confidence: 'high'
              });
            }

            // Check if DOI available when original DOI was broken
            if (record.doi && (!citation.doi || citation.doi !== record.doi)) {
              alternatives.suggestions.push({
                source: 'PubMed Central',
                type: 'pmc_doi',
                newDOI: record.doi,
                url: `https://doi.org/${record.doi}`,
                confidence: 'high'
              });
            }
          }
        }
      } catch (error) {
        console.log(`   PubMed Central search failed: ${error.message}`);
      }

      await delay(333); // Rate limiting for PubMed APIs
    }

    // Search by title if no alternatives found yet
    if (alternatives.suggestions.length === 0) {
      console.log(`   Searching by title in CrossRef...`);
      try {
        // Search CrossRef by title
        const titleQuery = encodeURIComponent(citation.title);
        const searchUrl = `https://api.crossref.org/works?query.title=${titleQuery}&rows=5`;
        const response = await fetch(searchUrl, { timeout: 10000 });

        if (response.ok) {
          const data = await response.json();
          const items = data.message?.items || [];

          // Filter for close matches
          for (const item of items.slice(0, 3)) { // Top 3 results
            // Calculate simple title similarity (case-insensitive)
            const originalTitle = citation.title.toLowerCase();
            const resultTitle = (item.title?.[0] || '').toLowerCase();

            if (resultTitle.includes(originalTitle.substring(0, 30)) ||
                originalTitle.includes(resultTitle.substring(0, 30))) {
              alternatives.suggestions.push({
                source: 'CrossRef Title Search',
                type: 'similar_work',
                title: item.title?.[0],
                doi: item.DOI,
                url: `https://doi.org/${item.DOI}`,
                authors: item.author?.map(a => `${a.given} ${a.family}`).join(', '),
                confidence: 'low'
              });
            }
          }
        }
      } catch (error) {
        console.log(`   CrossRef title search failed: ${error.message}`);
      }
    }

    if (alternatives.suggestions.length > 0) {
      console.log(`   ✅ Found ${alternatives.suggestions.length} alternative source(s)`);
    } else {
      console.log(`   ⚠️  No alternative sources found`);
    }

  } catch (error) {
    console.error(`   ❌ Error finding alternatives: ${error.message}`);
  }

  return alternatives;
}

/**
 * Append verification results to the citation verification log
 * @param {Object} report - Verification report
 * @returns {Promise<string>} - Path to updated log file
 */
async function appendToLog(report) {
  const logFilePath = path.join(__dirname, '../docs/operations/citation-verification-log.md');

  console.log(`📝 Appending to verification log: ${logFilePath}`);

  try {
    const date = new Date(report.verification_date);
    const dateStr = date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });

    // Calculate next verification date (3 months from now)
    const nextDate = new Date(date);
    nextDate.setMonth(nextDate.getMonth() + 3);
    const nextDateStr = nextDate.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });

    let logEntry = `\n## ${dateStr} Quarterly Verification\n\n`;
    logEntry += `### Summary\n\n`;
    logEntry += `- **Total Citations**: ${report.total_citations}\n`;
    logEntry += `- **Verified**: ${report.verified_count} ✅\n`;
    logEntry += `- **Broken**: ${report.broken_count} ⚠️\n`;
    logEntry += `- **Retracted**: ${report.warning_count} ❌\n\n`;

    if (report.broken_citations.length > 0 || report.retracted_papers.length > 0) {
      logEntry += `### Actions Taken\n\n`;

      let actionNumber = 1;

      // Log retracted papers
      for (const paper of report.retracted_papers) {
        logEntry += `${actionNumber}. **Citation ${paper.citation_id}** (${paper.article_title}): `;
        logEntry += `Retracted paper detected. **Action Required**: Remove citation and find replacement source.\n`;
        actionNumber++;
      }

      // Log broken citations
      for (const citation of report.broken_citations) {
        logEntry += `${actionNumber}. **Citation ${citation.citation_id}** (${citation.article_title}): `;
        logEntry += `${citation.error}. **Action Required**: Fix or replace citation.\n`;
        actionNumber++;
      }

      logEntry += `\n`;
    } else {
      logEntry += `### Actions Taken\n\n`;
      logEntry += `No actions required. All citations verified successfully.\n\n`;
    }

    logEntry += `### Next Verification Due\n\n`;
    logEntry += `- **${nextDateStr}** (3 months from verification date)\n\n`;
    logEntry += `---\n`;

    // Append to log file
    await fs.appendFile(logFilePath, logEntry, 'utf8');

    console.log('✅ Verification log updated');
    return logFilePath;
  } catch (error) {
    console.error('❌ Error appending to log:', error);
    throw error;
  }
}

/**
 * Update Firestore with verification status for each article
 * @param {Object} report - Verification report with results
 * @returns {Promise<void>}
 */
async function updateFirestoreVerificationStatus(report) {
  console.log('\n📝 Updating Firestore with verification status...');

  try {
    // Group results by article
    const articleUpdates = {};

    for (const detail of report.details) {
      if (!articleUpdates[detail.article_id]) {
        articleUpdates[detail.article_id] = {
          articleId: detail.article_id,
          articleTitle: detail.article_title,
          hasIssues: false,
          hasRetracted: false
        };
      }

      if (detail.has_issues) {
        articleUpdates[detail.article_id].hasIssues = true;
      }
      if (detail.retracted) {
        articleUpdates[detail.article_id].hasRetracted = true;
      }
    }

    // Prepare batch write
    const batch = db.batch();
    const verificationTimestamp = admin.firestore.Timestamp.fromDate(new Date(report.verification_date));

    for (const [articleId, update] of Object.entries(articleUpdates)) {
      const articleRef = db.collection('educational_resources').doc(articleId);

      // Determine verification status
      let verificationStatus;
      if (update.hasRetracted) {
        verificationStatus = 'needs_review'; // Critical: has retracted papers
      } else if (update.hasIssues) {
        verificationStatus = 'broken_links'; // Has broken links or issues
      } else {
        verificationStatus = 'verified'; // All citations verified successfully
      }

      console.log(`   ${articleId}: ${verificationStatus}`);

      // Update document with verification fields
      batch.update(articleRef, {
        last_verified: verificationTimestamp,
        verification_status: verificationStatus
      });
    }

    // Commit batch write
    await batch.commit();
    console.log(`✅ Updated ${Object.keys(articleUpdates).length} articles in Firestore`);

  } catch (error) {
    console.error('❌ Error updating Firestore:', error);
    throw error;
  }
}

// Export functions for testing
module.exports = {
  initializeFirebase,
  verifyDOI,
  verifyPMID,
  verifyURL,
  loadEducationalResources,
  extractCitations,
  verifyCitations,
  generateReport,
  saveReportJSON,
  saveReportMarkdown,
  generateMarkdownSummary,
  findAlternativeSource,
  appendToLog,
  updateFirestoreVerificationStatus
};

// Run if executed directly
if (require.main === module) {
  (async () => {
    try {
      console.log('🚀 Citation Verification Script Starting...\n');

      // Initialize Firebase
      initializeFirebase();

      // Load articles
      const resources = await loadEducationalResources();

      // Extract citations
      const citations = extractCitations(resources);

      if (citations.length === 0) {
        console.log('⚠️  No citations found to verify.');
        process.exit(0);
      }

      // Verify citations
      const results = await verifyCitations(citations);

      // Generate report
      const report = generateReport(results);

      // Save reports
      await saveReportJSON(report);
      await saveReportMarkdown(report);

      // Update Firestore with verification status
      await updateFirestoreVerificationStatus(report);

      // Append to verification log
      await appendToLog(report);

      // Display summary
      console.log('\n' + '='.repeat(60));
      console.log('VERIFICATION SUMMARY');
      console.log('='.repeat(60));
      console.log(`Total Citations: ${report.total_citations}`);
      console.log(`Verified: ${report.verified_count} ✅`);
      console.log(`Broken/Issues: ${report.broken_count} ⚠️`);
      console.log(`Retracted Papers: ${report.warning_count} ❌`);
      console.log('='.repeat(60));

      if (report.warning_count > 0 || report.broken_count > 0) {
        console.log('\n⚠️  Action required: Review generated reports for details');
      }

      console.log('\n✅ Script completed successfully');
      process.exit(0);
    } catch (error) {
      console.error('\n❌ Script failed:', error);
      process.exit(1);
    }
  })();
}
