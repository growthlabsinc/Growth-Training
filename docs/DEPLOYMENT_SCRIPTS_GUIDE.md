# Knowledge Base Deployment Scripts Guide

## Overview

This guide provides comprehensive documentation for the Growth Training knowledge base deployment automation scripts. These scripts enable reliable, versioned deployment of AI Coach knowledge content to Firebase Firestore.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Script Inventory](#script-inventory)
3. [Usage Examples](#usage-examples)
4. [Deployment Workflow](#deployment-workflow)
5. [Troubleshooting](#troubleshooting)
6. [Best Practices](#best-practices)

## Prerequisites

### Required Setup

1. **Service Account Key**
   ```bash
   # Place your service account key at:
   ./service-account-key.json
   # Or set environment variable:
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
   ```

2. **NPM Dependencies**
   ```bash
   cd scripts
   npm install commander cli-progress chalk firebase-admin
   ```

3. **Firebase Project**
   - Project ID: `growth-training-app`
   - Collection: `ai_coach_knowledge`
   - Ensure Firestore is enabled

## Script Inventory

### 1. deployGrowthTrainingKnowledge.js

**Purpose**: Main deployment script for batch uploading knowledge documents

**Features**:
- Batch upload with 500-document chunks (Firestore limit)
- Document validation
- Progress tracking
- Version management
- Deployment recording

**Usage**:
```bash
# Deploy from single JSON file
node deployGrowthTrainingKnowledge.js knowledge.json

# Deploy from directory of JSON files
node deployGrowthTrainingKnowledge.js ./knowledge-docs/

# Dry run mode (no actual changes)
node deployGrowthTrainingKnowledge.js knowledge.json --dry-run

# Verbose error reporting
node deployGrowthTrainingKnowledge.js knowledge.json --verbose

# Deploy specific category
node deployGrowthTrainingKnowledge.js knowledge.json --category safety

# Deploy high-priority documents only
node deployGrowthTrainingKnowledge.js knowledge.json --priority 8
```

**Document Schema**:
```json
{
  "id": "unique-document-id",
  "title": "Document Title",
  "content": "Full content text...",
  "category": "safety|length|girth|eq|equipment|recovery|general",
  "keywords": ["keyword1", "keyword2"],
  "priority": 1-10,
  "version": 1,
  "updatedAt": "timestamp",
  "deployedBy": "script-name"
}
```

### 2. deployPESafetyGuidelines.js

**Purpose**: Specialized deployment for safety-critical content

**Features**:
- Enhanced validation for safety content
- Medical disclaimer verification
- Automatic high-priority assignment (8-10)
- Safety keyword enforcement

**Usage**:
```bash
# Deploy from safety JSON file
node deployPESafetyGuidelines.js --source safety-docs.json

# Generate and deploy default safety documents
node deployPESafetyGuidelines.js --generate

# Dry run with verbose output
node deployPESafetyGuidelines.js --source safety.json --dry-run --verbose
```

**Safety Requirements**:
- Must include medical disclaimer keywords
- Priority must be 8-10
- Category should be 'safety', 'recovery', or 'medical'
- Must contain safety warning terms

### 3. deployEquipmentGuides.js

**Purpose**: Deploy equipment-specific guides with categorization

**Equipment Types**:
- `pumps` - Vacuum pumps and water pumps
- `hangers` - Weight hanging devices
- `extenders` - Traction devices
- `clamps` - Clamping devices
- `rings` - Constriction rings
- `stretchers` - Manual stretching aids
- `accessories` - Other equipment

**Usage**:
```bash
# Deploy equipment guides from file
node deployEquipmentGuides.js --source equipment.json

# Generate sample equipment guides
node deployEquipmentGuides.js --generate

# Deploy specific equipment type
node deployEquipmentGuides.js --source equipment.json --type pumps

# Dry run mode
node deployEquipmentGuides.js --source equipment.json --dry-run
```

### 4. rollbackDeployment.js

**Purpose**: Rollback problematic deployments

**Features**:
- Interactive deployment selection
- Backup and restore functionality
- Point-in-time backups
- Version history rollback

**Usage**:
```bash
# Interactive rollback (shows last 10 deployments)
node rollbackDeployment.js

# List recent deployments only
node rollbackDeployment.js --list

# Show more deployments
node rollbackDeployment.js --limit 20

# Create backup
node rollbackDeployment.js --backup

# Restore from backup file
node rollbackDeployment.js --restore ./backups/backup_1234567890.json
```

### 5. auditKnowledgeBase.js

**Purpose**: Verify knowledge base integrity

**Checks**:
- Missing required fields
- Invalid priority values
- Missing keywords
- Short content (<100 chars)
- Duplicate content detection
- Category distribution
- Version tracking

**Usage**:
```bash
# Basic audit
node auditKnowledgeBase.js

# Export audit report
node auditKnowledgeBase.js --export

# Include content in export
node auditKnowledgeBase.js --export --include-content

# Check for duplicates
node auditKnowledgeBase.js --duplicates

# Verify search functionality
node auditKnowledgeBase.js --search "pump,safety,beginner"

# Verbose mode with all warnings
node auditKnowledgeBase.js --verbose

# Strict mode (warnings as errors)
node auditKnowledgeBase.js --strict
```

### 6. knowledgeStatsReporter.js

**Purpose**: Generate comprehensive statistics

**Metrics**:
- Document counts by category/priority
- Content length analysis
- Keyword distribution
- Version information
- Recent activity tracking
- Quality indicators

**Usage**:
```bash
# Generate and display statistics
node knowledgeStatsReporter.js

# Export statistics to JSON
node knowledgeStatsReporter.js --export json

# Export to CSV
node knowledgeStatsReporter.js --export csv

# Compare growth over time
node knowledgeStatsReporter.js --compare 7

# Quiet mode (no console output)
node knowledgeStatsReporter.js --quiet --export json

# Output raw JSON
node knowledgeStatsReporter.js --json
```

### 7. verifyDeployment.js

**Purpose**: Verify deployment success

**Verification Checks**:
- Document count validation
- Required fields integrity
- Version consistency
- Priority range validation
- Safety content compliance

**Usage**:
```bash
# Verify latest deployment
node verifyDeployment.js

# Verify specific deployment
node verifyDeployment.js --deployment deployment-id-here

# Verify multiple recent deployments
node verifyDeployment.js --all 5

# Export verification report
node verifyDeployment.js --export
```

## Deployment Workflow

### Standard Deployment Process

1. **Prepare Content**
   ```bash
   # Organize your JSON files
   ./knowledge-content/
   ├── safety-guidelines.json
   ├── equipment-guides.json
   └── general-knowledge.json
   ```

2. **Audit Current State**
   ```bash
   # Check current knowledge base
   node auditKnowledgeBase.js
   
   # Generate statistics
   node knowledgeStatsReporter.js
   ```

3. **Create Backup**
   ```bash
   # Create point-in-time backup
   node rollbackDeployment.js --backup
   ```

4. **Deploy Content**
   ```bash
   # Dry run first
   node deployGrowthTrainingKnowledge.js ./knowledge-content/ --dry-run
   
   # Deploy safety content first (high priority)
   node deployPESafetyGuidelines.js --source ./knowledge-content/safety-guidelines.json
   
   # Deploy equipment guides
   node deployEquipmentGuides.js --source ./knowledge-content/equipment-guides.json
   
   # Deploy general knowledge
   node deployGrowthTrainingKnowledge.js ./knowledge-content/general-knowledge.json
   ```

5. **Verify Deployment**
   ```bash
   # Verify latest deployment
   node verifyDeployment.js
   
   # Run audit to check integrity
   node auditKnowledgeBase.js
   ```

6. **Rollback if Needed**
   ```bash
   # If issues found, rollback
   node rollbackDeployment.js
   # Select deployment number to rollback
   ```

### Emergency Rollback

```bash
# Quick rollback to last good state
node rollbackDeployment.js --restore ./backups/last-known-good.json
```

## Troubleshooting

### Common Issues

#### 1. Service Account Key Not Found
```bash
# Error: Service account key not found
# Solution:
export GOOGLE_APPLICATION_CREDENTIALS="/absolute/path/to/key.json"
```

#### 2. NPM Dependencies Missing
```bash
# Error: Cannot find module 'commander'
# Solution:
cd scripts && npm install
```

#### 3. Firestore Permission Denied
```bash
# Error: 7 PERMISSION_DENIED
# Solution: Ensure service account has Firestore Admin role
```

#### 4. Document Validation Failures
```bash
# Use verbose mode to see specific errors
node deployGrowthTrainingKnowledge.js content.json --verbose
```

#### 5. Batch Size Exceeded
```bash
# Error: Batch size exceeded 500
# Solution: Script automatically handles this, but ensure no manual batching
```

### Debug Mode

```bash
# Enable debug output
DEBUG=* node deployGrowthTrainingKnowledge.js content.json
```

## Best Practices

### 1. Content Preparation
- Validate JSON structure before deployment
- Use consistent ID naming: `category-topic-subtopic`
- Keep content between 200-2000 characters
- Include 3-10 relevant keywords per document

### 2. Safety First
- Always deploy safety content with highest priority
- Include medical disclaimers in safety documents
- Test safety content search functionality

### 3. Version Control
- Commit knowledge JSON files to git
- Tag deployments with version numbers
- Document changes in deployment notes

### 4. Testing Strategy
```bash
# Always test in this order:
1. node script.js --dry-run              # Verify no changes
2. node script.js --dry-run --verbose    # Check for errors
3. node rollbackDeployment.js --backup   # Create backup
4. node script.js                        # Actual deployment
5. node verifyDeployment.js             # Verify success
```

### 5. Monitoring
- Check deployment records in Firestore
- Monitor error rates after deployment
- Track search query performance

### 6. Documentation
- Document custom categories added
- Keep deployment logs
- Update this guide with new patterns

## Script Development

### Adding New Scripts

Template for new deployment scripts:

```javascript
#!/usr/bin/env node

const admin = require('firebase-admin');
const { program } = require('commander');
const chalk = require('chalk');

// Your script logic here

program
  .name('scriptName')
  .description('Script description')
  .version('1.0.0')
  .option('-d, --dry-run', 'Run without making changes')
  .action((options) => {
    // Implementation
  });

program.parse();
```

### Testing Scripts

```bash
# Use Firebase emulator for testing
firebase emulators:start --only firestore

# Set emulator environment
export FIRESTORE_EMULATOR_HOST="localhost:8080"

# Run script against emulator
node yourScript.js --dry-run
```

## Support

For issues or questions:
1. Check script help: `node scriptName.js --help`
2. Review error messages with `--verbose` flag
3. Consult Firebase logs for server-side errors
4. Create detailed bug reports with:
   - Script name and version
   - Full error message
   - Input file sample
   - Deployment environment

---

*Last Updated: Story 3.5 Completion*
*Version: 1.0.0*