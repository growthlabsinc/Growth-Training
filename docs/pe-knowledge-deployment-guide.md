# PE Knowledge Base Deployment Guide

**Story Reference**: 3.2 - Deploy PE Knowledge Base
**Date**: 2025-01-21
**Status**: Production Ready

## Overview

This guide documents the complete PE Knowledge Base system for the AI Coach, including deployment, maintenance, and troubleshooting procedures.

## Architecture

### Knowledge Schema
```javascript
{
  id: "unique-identifier",
  category: "length|girth|eq|safety|equipment|progression",
  title: "Document title",
  content: "Full knowledge content (markdown supported)",
  keywords: ["array", "of", "searchable", "terms"],
  priority: 1-10, // Importance level for ranking
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### Categories and Coverage

| Category | Documents | Focus |
|----------|-----------|-------|
| **safety** | 3 | Injury prevention, recovery protocols, medical considerations |
| **length** | 3 | Manual stretching, hanging, extenders |
| **girth** | 3 | Pumping, manual exercises, clamping |
| **eq** | 3 | Kegels, cardio, lifestyle factors |
| **equipment** | 1 | Device selection and safety |
| **progression** | 1 | Realistic timelines and expectations |

**Total**: 14 comprehensive knowledge documents

## Deployment

### Prerequisites
- Firebase CLI installed and authenticated
- Node.js 20+ environment
- gcloud authenticated for project `growth-training-app`
- Access to Firestore collection `ai_coach_knowledge`

### Deployment Process

1. **Initial Deployment**
   ```bash
   cd functions
   node deployPEKnowledge.js
   ```

2. **Verification**
   ```bash
   cd ..
   python3 scripts/verify_pe_knowledge_deployment.py
   ```

3. **AI Integration Testing**
   ```bash
   python3 scripts/test_ai_coach_pe_integration.py
   ```

### Expected Results
- 14 documents deployed successfully
- All 6 categories populated
- Knowledge search functional
- AI Coach integration verified

## Maintenance

### Regular Tasks

#### Monthly Review
- Run verification script to check document count
- Test AI Coach responses for quality
- Review any reported issues or gaps

#### Content Updates
Use the update scripts when content needs revision:
```bash
node functions/updatePEKnowledge.js --category [category] --id [document-id]
```

#### Knowledge Audit
```bash
python3 scripts/audit_pe_knowledge.py
```

### Version Control
- All knowledge content is version-controlled in deployment script
- Original Epic 2 content preserved as source material
- Changes documented in deployment script comments

## Troubleshooting

### Common Issues

#### Authentication Errors
```bash
# Re-authenticate with gcloud
gcloud auth login --update-adc
gcloud config set project growth-training-app
```

#### Missing Documents
1. Check deployment logs for errors
2. Verify Firestore permissions
3. Re-run deployment script
4. Check network connectivity

#### Search Not Working
1. Verify documents have proper keywords
2. Test with simple queries first
3. Check knowledge search function in `vertexAiProxy/`
4. Review AI Coach system prompts

#### No AI Responses
1. Confirm knowledge base is populated
2. Test fallback knowledge system
3. Check Vertex AI integration
4. Review system prompt configuration

## Scripts Reference

### Deployment Scripts
- `functions/deployPEKnowledge.js` - Main deployment script
- `functions/updatePEKnowledge.js` - Update existing knowledge
- `functions/rollbackPEKnowledge.js` - Emergency rollback

### Verification Scripts
- `scripts/verify_pe_knowledge_deployment.py` - Post-deployment verification
- `scripts/test_ai_coach_pe_integration.py` - AI integration testing
- `scripts/audit_pe_knowledge.py` - Regular audit checks

### Maintenance Scripts
- `scripts/refresh_pe_knowledge.py` - Refresh all documents
- `scripts/backup_pe_knowledge.py` - Create knowledge backup
- `scripts/validate_pe_content.py` - Content quality validation

## Content Guidelines

### Safety Requirements
- All documents MUST include medical disclaimers
- Safety information has priority 8-10
- Injury prevention emphasized in all categories
- Progressive training approach mandated

### Content Standards
- Evidence-based information only
- Conservative progression recommendations
- Clear technique instructions
- Realistic expectation setting
- Medical consultation encouragement

### Prohibited Content
- Angion Method references (fully removed)
- Overly aggressive techniques
- Unsubstantiated claims
- Medical advice or diagnosis
- Equipment endorsements without safety focus

## AI Coach Integration

### System Prompts
AI Coach prompts updated to:
- Prioritize safety in all responses
- Use deployed knowledge for context
- Include medical disclaimers
- Focus on evidence-based PE training
- Avoid Angion methodology

### Knowledge Search
- Searches `ai_coach_knowledge` collection
- Keyword matching on content and metadata
- Priority-based ranking
- Safety content prioritized
- Fallback to safety guidelines

### Response Generation
1. User query received
2. Knowledge search performed
3. Relevant documents retrieved
4. Safety-first response generated
5. Medical disclaimers included

## Backup and Recovery

### Backup Strategy
- Knowledge deployed from version-controlled script
- Original content preserved in deployment files
- Regular exports to JSON format
- Archive maintained in `archive/` directory

### Recovery Procedures
1. **Partial Failure**: Re-run deployment script
2. **Complete Loss**: Deploy from script + verify
3. **Corruption**: Use rollback script + fresh deploy
4. **Emergency**: Activate fallback knowledge system

### Rollback Plan
```bash
# Emergency rollback to fallback knowledge only
node functions/rollbackPEKnowledge.js --emergency
python3 scripts/verify_rollback.py
```

## Support and Escalation

### Level 1: Self-Service
- Run verification scripts
- Check deployment logs
- Review troubleshooting guide
- Test with simple queries

### Level 2: Developer Support
- Review Firebase console
- Check function logs
- Examine Vertex AI integration
- Test knowledge search directly

### Level 3: Architecture Review
- Evaluate schema changes
- Review AI integration
- Consider knowledge expansion
- Plan system improvements

## Change Management

### Content Updates
1. Update deployment script
2. Test in development environment
3. Run verification suite
4. Deploy to production
5. Verify AI integration
6. Document changes

### Schema Changes
1. Design backward-compatible changes
2. Update deployment script
3. Test migration procedures
4. Plan rollback strategy
5. Execute deployment
6. Monitor system health

## Monitoring

### Key Metrics
- Knowledge document count (target: 14)
- Category coverage (target: 6 categories)
- Search success rate (target: >95%)
- AI response quality (target: safety-first)
- Zero Angion content (target: 0 references)

### Health Checks
- Daily: Automated document count verification
- Weekly: AI response quality sampling
- Monthly: Comprehensive content audit
- Quarterly: Knowledge expansion review

## Contact Information

**Primary Developer**: James (Developer Agent)
**Product Owner**: Sarah (Product Owner)
**Scrum Master**: Bob (Scrum Master)

**Documentation**: This file + inline code comments
**Support**: Run verification scripts + check logs
**Escalation**: Review Firebase console + function logs