# Citation Verification System

Automated system for verifying academic citations in Growth Training educational articles.

## Overview

The citation verification system validates all citations from the 8 educational articles by:
- Checking DOI resolution
- Validating PubMed IDs
- Detecting retracted papers
- Finding alternative sources for broken citations
- Generating comprehensive reports
- Updating Firestore with verification status
- Maintaining a historical verification log

## Quick Start

### Prerequisites

1. **Firebase Admin SDK credentials**: Set `GOOGLE_APPLICATION_CREDENTIALS` environment variable:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
   ```

2. **Node.js dependencies**: Install from project root:
   ```bash
   npm install
   ```

### Running Verification

**From project root**:
```bash
npm run verify-citations
```

**From functions directory**:
```bash
cd functions
npm run verify-citations
```

**Directly**:
```bash
node scripts/verify-citations.js
```

## Verification Process

### 1. Citation Verification

The script verifies all 55 citations across 8 articles:

- **DOI Verification**: Checks if DOI resolves (HTTP 200/302)
  - Rate limit: 1 request/second
  - Timeout: 10 seconds

- **PubMed Verification**: Validates PMID and checks retraction status
  - Rate limit: 3 requests/second
  - Timeout: 10 seconds
  - Retraction detection included

- **URL Verification**: Checks general URLs if no DOI/PMID
  - Rate limit: 1 request/second
  - Timeout: 10 seconds

### 2. Report Generation

Two reports are generated:

**JSON Report** (`docs/operations/citation-verification-report-{date}.json`):
- Complete verification details
- Status of each citation
- Broken citation list
- Retracted paper list

**Markdown Summary** (`docs/operations/citation-verification-summary-{date}.md`):
- Human-readable summary
- Action items for broken citations
- Retraction warnings

### 3. Firestore Updates

Each article document is updated with:
- `last_verified`: Timestamp of verification
- `verification_status`: One of:
  - `"verified"` - All citations verified successfully
  - `"broken_links"` - Has broken links or issues
  - `"needs_review"` - Has retracted papers (critical)

### 4. Verification Log

Historical log maintained at `docs/operations/citation-verification-log.md`:
- Verification date
- Summary statistics
- Actions taken
- Next verification due date (3 months)

## Quarterly Schedule

Citations should be verified **quarterly** (every 3 months):

1. Run verification script
2. Review generated reports
3. Fix broken citations
4. Remove/replace retracted papers
5. Update log with actions taken
6. Set calendar reminder for next verification

**Recommended Schedule**:
- January, April, July, October

## Understanding Results

### Verification Status Codes

**DOI Status**:
- `200/302`: Valid (success/redirect)
- `404`: Broken link
- `Error`: Network/timeout issue

**PMID Status**:
- `valid: true`: Article found in PubMed
- `valid: false`: Not found or error
- `retracted: true`: ⚠️ Paper has been retracted

**Verification Status**:
- `verified`: ✅ All citations working
- `broken_links`: ⚠️ Some citations broken
- `needs_review`: ❌ Retracted papers found

### Example Output

```
============================================================
VERIFICATION SUMMARY
============================================================
Total Citations: 55
Verified: 52 ✅
Broken/Issues: 2 ⚠️
Retracted Papers: 1 ❌
============================================================
```

## Handling Issues

### Broken DOI/PMID

1. Check the JSON report for error details
2. Run alternative source finder (automatic)
3. Options:
   - Update DOI if article moved
   - Use PubMed Central archive link
   - Find updated publication

### Retracted Papers

**CRITICAL**: Retracted papers must be removed immediately.

1. Identify retracted citation in report
2. Find replacement source on same topic
3. Update article markdown file
4. Redeploy article to Firestore
5. Document action in verification log

### Rate Limiting

If you encounter rate limiting:
- DOI.org: Wait 1 hour, resume
- PubMed: Increase delay in script (currently 333ms)
- Script includes automatic delays

## Alternative Source Finder

Automatically searches for alternatives when citations break:

1. **CrossRef API**: Check for updated DOI
2. **PubMed Central**: Find archived versions
3. **Title Search**: Find similar works

Results saved in `broken_citations` array with suggestions.

## Error Handling

### Common Errors

**"Firebase credentials not found"**:
```bash
# Set credentials path
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

**"Error loading educational resources"**:
- Check Firebase project ID in script
- Verify Firestore permissions
- Confirm collection name: `educational_resources`

**"Network timeout"**:
- Check internet connection
- Increase timeout in script (currently 10s)
- Retry verification

**"Rate limit exceeded"**:
- Wait 1 hour
- Reduce request rate in script
- Use exponential backoff

## Testing

Run test suite:

```bash
npm run test:citations
# or
node scripts/verify-citations.test.js
```

Tests include:
- Valid DOI verification
- Invalid DOI handling
- Valid PMID verification
- Invalid PMID handling
- Report generation
- Markdown summary generation

## File Locations

```
scripts/
├── verify-citations.js           # Main verification script
├── verify-citations.test.js      # Test suite
└── README-citation-verification.md  # This file

docs/operations/
├── citation-verification-log.md              # Historical log
├── citation-verification-report-{date}.json  # JSON report
└── citation-verification-summary-{date}.md   # Markdown summary
```

## Script Configuration

Key constants in `verify-citations.js`:

```javascript
// Rate limiting
DOI_DELAY = 1000ms    // 1 request/second
PMID_DELAY = 333ms    // 3 requests/second

// Timeouts
REQUEST_TIMEOUT = 10000ms  // 10 seconds

// Project
FIRESTORE_PROJECT = 'growth-training-app'
COLLECTION_NAME = 'educational_resources'
```

## Troubleshooting

### Script hangs during verification
- Check network connection
- Verify external API availability:
  - https://doi.org
  - https://eutils.ncbi.nlm.nih.gov
  - https://api.crossref.org

### Missing citations in report
- Confirm articles deployed to Firestore
- Check citation array format
- Verify collection/document IDs

### Firestore update fails
- Check Firebase Admin SDK permissions
- Verify batch write limits (500 operations max)
- Confirm document references are correct

## API Documentation

### External APIs Used

**DOI.org**:
- Endpoint: `https://doi.org/{doi}`
- Method: HEAD request
- Rate limit: ~1 req/sec recommended
- Docs: https://www.doi.org/the-identifier/resources/factsheets/doi-system-and-standard

**PubMed E-utilities**:
- Endpoint: `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi`
- Rate limit: 3 req/sec (with API key), 1 req/sec (without)
- Docs: https://www.ncbi.nlm.nih.gov/books/NBK25501/

**CrossRef API**:
- Endpoint: `https://api.crossref.org/works`
- No authentication required
- Rate limit: 50 req/sec (polite pool with contact email)
- Docs: https://api.crossref.org/swagger-ui/index.html

**PubMed Central ID Converter**:
- Endpoint: `https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/`
- Rate limit: Same as E-utilities
- Docs: https://www.ncbi.nlm.nih.gov/pmc/tools/id-converter-api/

## Support

For issues or questions:
1. Check this documentation
2. Review error messages in script output
3. Examine generated reports for details
4. Contact development team

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-10-07 | Initial implementation (Story 7.6) |

---

**Maintenance Schedule**: Run quarterly verification every 3 months.
**Last Updated**: October 7, 2025
**Owner**: Content Team + Development Team
