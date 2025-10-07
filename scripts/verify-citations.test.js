/**
 * Test suite for citation verification script
 *
 * Run with: npm test:citations or node scripts/verify-citations.test.js
 */

const {
  verifyDOI,
  verifyPMID,
  verifyURL,
  generateReport,
  generateMarkdownSummary
} = require('./verify-citations');

// Simple test runner (no need for Jest for basic tests)
class TestRunner {
  constructor() {
    this.passed = 0;
    this.failed = 0;
    this.tests = [];
  }

  async test(name, fn) {
    try {
      await fn();
      console.log(`✅ PASS: ${name}`);
      this.passed++;
    } catch (error) {
      console.log(`❌ FAIL: ${name}`);
      console.log(`   Error: ${error.message}`);
      this.failed++;
    }
  }

  assert(condition, message) {
    if (!condition) {
      throw new Error(message || 'Assertion failed');
    }
  }

  async run() {
    console.log('\n🧪 Running Citation Verification Tests\n');

    // Test 1: Valid DOI
    await this.test('verifyDOI() - Valid DOI returns status 200', async () => {
      const result = await verifyDOI('10.1111/febs.16938');
      this.assert(result.valid, 'DOI should be valid');
      this.assert(result.status === 200 || result.status === 302, 'Status should be 200 or 302 (redirect)');
      this.assert(result.resolvedUrl, 'Should have resolved URL');
    });

    // Test 2: Invalid DOI
    await this.test('verifyDOI() - Invalid DOI returns error', async () => {
      const result = await verifyDOI('10.9999/invalid.doi.9999999');
      this.assert(!result.valid, 'Invalid DOI should not be valid');
      this.assert(result.status === 404 || result.error, 'Should have error status or error message');
    });

    // Test 3: Valid PMID
    await this.test('verifyPMID() - Valid PMID returns article data', async () => {
      const result = await verifyPMID('37940585'); // Valid PMID from article 1
      this.assert(result.valid, 'PMID should be valid');
      this.assert(!result.retracted, 'Article should not be retracted');
    });

    // Test 4: Invalid PMID
    await this.test('verifyPMID() - Invalid PMID returns error', async () => {
      const result = await verifyPMID('99999999999');
      this.assert(!result.valid, 'Invalid PMID should not be valid');
    });

    // Test 5: Empty DOI
    await this.test('verifyDOI() - Empty DOI handled gracefully', async () => {
      const result = await verifyDOI('');
      this.assert(!result.valid, 'Empty DOI should not be valid');
      this.assert(result.error, 'Should have error message');
    });

    // Test 6: Empty PMID
    await this.test('verifyPMID() - Empty PMID handled gracefully', async () => {
      const result = await verifyPMID('');
      this.assert(!result.valid, 'Empty PMID should not be valid');
      this.assert(result.error, 'Should have error message');
    });

    // Test 7: Generate report
    await this.test('generateReport() - Creates proper report structure', async () => {
      const mockResults = [
        {
          articleId: 'test-article-1',
          articleTitle: 'Test Article',
          citationId: 'test-citation-1',
          citation: { title: 'Test Citation', authors: 'Smith J', year: '2024', journal: 'Test J' },
          doi: '10.1111/test',
          pmid: null,
          url: null,
          verification: {
            timestamp: new Date().toISOString(),
            doiStatus: { valid: true, status: 200 },
            pmidStatus: null,
            urlStatus: null,
            hasIssues: false,
            isValid: true,
            issues: []
          }
        },
        {
          articleId: 'test-article-1',
          articleTitle: 'Test Article',
          citationId: 'test-citation-2',
          citation: { title: 'Broken Citation', authors: 'Doe J', year: '2023', journal: 'Test J' },
          doi: '10.9999/broken',
          pmid: null,
          url: null,
          verification: {
            timestamp: new Date().toISOString(),
            doiStatus: { valid: false, status: 404 },
            pmidStatus: null,
            urlStatus: null,
            hasIssues: true,
            isValid: true,
            issues: ['DOI verification failed: HTTP 404']
          }
        }
      ];

      const report = generateReport(mockResults);

      this.assert(report.total_citations === 2, 'Should have 2 total citations');
      this.assert(report.verified_count === 1, 'Should have 1 verified citation');
      this.assert(report.broken_count === 1, 'Should have 1 broken citation');
      this.assert(report.warning_count === 0, 'Should have 0 retracted papers');
      this.assert(report.details.length === 2, 'Should have 2 detail entries');
      this.assert(report.broken_citations.length === 1, 'Should have 1 broken citation entry');
    });

    // Test 8: Generate markdown summary
    await this.test('generateMarkdownSummary() - Creates markdown format', async () => {
      const mockReport = {
        verification_date: new Date().toISOString(),
        total_citations: 5,
        verified_count: 4,
        broken_count: 1,
        warning_count: 0,
        broken_citations: [
          {
            article_id: 'test-1',
            article_title: 'Test Article',
            citation_id: 'test-cite-1',
            citation_title: 'Broken Citation',
            doi: '10.9999/broken',
            error: 'HTTP 404'
          }
        ],
        retracted_papers: []
      };

      const markdown = generateMarkdownSummary(mockReport);

      this.assert(markdown.includes('# Citation Verification Report'), 'Should have title');
      this.assert(markdown.includes('Total Citations'), 'Should have total citations');
      this.assert(markdown.includes('Verified'), 'Should have verified count');
      this.assert(markdown.includes('Broken/Issues'), 'Should have broken count');
      this.assert(markdown.includes('## ⚠️  Broken Citations'), 'Should have broken citations section');
    });

    // Summary
    console.log('\n' + '='.repeat(60));
    console.log('TEST SUMMARY');
    console.log('='.repeat(60));
    console.log(`Passed: ${this.passed} ✅`);
    console.log(`Failed: ${this.failed} ${this.failed > 0 ? '❌' : ''}`);
    console.log('='.repeat(60));

    if (this.failed > 0) {
      console.log('\n⚠️  Some tests failed. Review errors above.');
      process.exit(1);
    } else {
      console.log('\n✅ All tests passed!');
      process.exit(0);
    }
  }
}

// Run tests if executed directly
if (require.main === module) {
  const runner = new TestRunner();
  runner.run().catch(error => {
    console.error('\n❌ Test runner failed:', error);
    process.exit(1);
  });
}

module.exports = { TestRunner };
