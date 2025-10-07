# Epic 7: Learning Center Content - Scientific Articles

## Epic Overview
Populate the Learning Center Resources section with 8 scientifically-cited educational articles covering PE training fundamentals, safety, and evidence-based practices. All articles must include proper scientific citations displayed both in-article and in the Settings FAQ section.

**Content Strategy**: Use Reddit scraper (`scripts/reddit-scraper/`) to extract educational content from PE community subreddits (r/TheScienceOfPE, r/GettingBigger, r/AJelqForYou, r/PEGym), then use AI to synthesize scraped data into well-written articles with verified scientific citations.

**Priority**: P1 - High
**Estimated Effort**: 5-7 days
**Dependencies**: None (Epic 5 complete)
**Owner**: Content Team + Development Team

## Epic Goals
- Scrape educational content from PE subreddits using existing Reddit scraper tools
- Use AI to synthesize scraped Reddit data into 8 high-quality, research-backed articles
- Extract and verify scientific citations from Reddit community sources
- Implement citation system for scientific references in iOS app
- Display citations in both article detail view and Settings FAQ
- Ensure content aligns with r/TheScienceOfPE and r/GettingBigger communities
- Maintain safety-first approach with medical disclaimers

## Acceptance Criteria
- [ ] Reddit scraper successfully extracts content for all 8 article topics
- [ ] AI synthesizes scraped data into 8 articles with verified citations
- [ ] All articles include 3-5 scientific citations in APA format
- [ ] Citation model implemented in Firestore
- [ ] Citations displayed in article detail view
- [ ] Citations accessible in Settings FAQ section
- [ ] All articles reviewed for accuracy and safety
- [ ] Content deployed to production Firestore

## User Stories

### Story 7.1: Reddit Content Scraping and Research
**As a** content creator,
**I want to** scrape educational content from PE subreddits using the Reddit scraper,
**So that** I can gather community knowledge and scientific references for article creation

**Tasks:**
- Set up Reddit API credentials in `.env` file
- Install Python dependencies for Reddit scraper
- Run `scrape_educational_articles.py` to gather content for 8 article topics
- Extract scientific citations (URLs to studies/papers) from Reddit posts
- Identify key points, warnings, and best practices from community
- Review scraped data for quality and relevance
- Extract Reddit URLs to academic sources (PubMed, DOI, etc.)

**Article Topics** (Aligned with scraper topics):
1. **The Science of Tissue Expansion** (Science) - scraper topic: `science_of_tissue_expansion`
2. **Understanding EQ and Blood Flow** (Science) - scraper topic: `understanding_eq_blood_flow`
3. **Injury Prevention and Recovery** (Safety) - scraper topic: `injury_prevention_recovery`
4. **PE Fundamentals for Beginners** (Basics) - scraper topic: `beginner_fundamentals`
5. **Heat Application and Its Benefits** (Technique) - scraper topic: `heat_application_benefits`
6. **Measuring and Tracking Progress** (Progression) - scraper topic: `measuring_tracking_progress`
7. **Supplements and Nutrition for PE** (Science) - scraper topic: `supplements_nutrition`
8. **Rest Days and Deconditioning** (Progression) - scraper topic: `rest_recovery_decon`

**Reddit Scraper Configuration:**
- **Target Subreddits**: r/TheScienceOfPE, r/GettingBigger, r/AJelqForYou, r/PEGym
- **Scraper Script**: `scripts/reddit-scraper/scrape_educational_articles.py`
- **Output**: `scripts/reddit-scraper/extracted_data/educational_content_raw.json`

**Data Extracted per Topic:**
- Top-rated posts (score > 10) matching keywords
- Wiki content from subreddit wikis
- Scientific mentions (study references, research claims)
- Key points (numbered lists, bullet points)
- Safety warnings and cautions
- Academic URLs (PubMed, DOI, ScienceDirect, Nature, Springer)

**Acceptance Criteria:**
- Reddit API credentials configured in `.env`
- Scraper successfully runs and extracts content for all 8 topics
- At least 10+ posts collected per topic
- Scientific citations (URLs) extracted from community posts
- Key points and warnings captured for each topic
- Output JSON file generated with structured data
- Data reviewed for quality and relevance to article creation

---

### Story 7.2: AI-Assisted Article Writing from Scraped Data
**As a** content creator,
**I want to** use Claude AI to synthesize scraped Reddit data into well-written articles with scientific citations,
**So that** I can efficiently create high-quality educational content

**Tasks:**
- Load scraped data from `educational_content_raw.json`
- For each of the 8 article topics, use Claude AI to:
  - Synthesize key points from Reddit posts into coherent article sections
  - Identify and verify scientific citations from extracted URLs
  - Format citations in APA 7th edition style
  - Generate article content following the Article Structure template
  - Include medical disclaimers and safety warnings
  - Cross-reference multiple Reddit sources for accuracy
- Create article content files in JSON format ready for Firestore
- Verify all extracted citations are accessible and valid
- Review AI-generated content for accuracy and tone

**Article Structure Template:**
```markdown
# {Title}

## Overview
Brief introduction (2-3 paragraphs)

## Key Concepts
Main content sections with headers

## Scientific Evidence
Research findings with inline citations [1]

## Safety Considerations
Prominent safety warnings

## Practical Application
How to apply the information

## Medical Disclaimer
Standard disclaimer text

## References
1. Author, A. A. (Year). Title. Journal Name, volume(issue), pages. doi:xxx
```

**Citation Verification Process:**
1. Extract URLs from scraped data (PubMed, DOI links, etc.)
2. Verify each URL is accessible
3. Extract proper citation metadata (authors, year, title, journal)
4. Format in APA 7th edition
5. Include DOI when available for permanence

**Acceptance Criteria:**
- All 8 articles written with 3-5 verified scientific citations each
- Citations follow APA 7th edition format
- Medical disclaimers included in all articles
- Content synthesized from multiple Reddit sources
- All citation URLs verified as accessible
- Articles saved as JSON with proper structure for Firestore
- Content reviewed for medical accuracy and safety

---

### Story 7.3: Extend EducationalResource Model
**As a** developer,
**I want to** extend the EducationalResource data model to support citations,
**So that** articles can reference scientific research

**Tasks:**
- Add `citations` array field to EducationalResource model
- Create Citation model (author, year, title, journal, url, doi)
- Update Firestore schema for educational_resources collection
- Add migration support for existing articles (backward compatibility)
- Update ViewModels to handle citations

**Data Model Updates:**
```swift
struct Citation: Codable, Hashable {
    let id: String
    let authors: String // e.g., "Smith, J., & Jones, A."
    let year: String
    let title: String
    let journal: String // e.g., "Journal of PE Research"
    let volume: String?
    let pages: String?
    let doi: String? // Digital Object Identifier
    let url: String? // Link to study
}

// Extend EducationalResource
struct EducationalResource {
    // ... existing fields
    let citations: [Citation]? // Array of citations
    let medicalDisclaimer: String? // Safety disclaimer text
}
```

**Firestore Structure:**
```
educational_resources/
├── {articleId}/
│   ├── title: "Article Title"
│   ├── content_text: "Article content..."
│   ├── category: "Science"
│   ├── citations: [
│   │   {
│   │     id: "citation1",
│   │     authors: "Smith, J., & Jones, A.",
│   │     year: "2023",
│   │     title: "Study Title",
│   │     journal: "Journal Name",
│   │     doi: "10.1234/example",
│   │     url: "https://..."
│   │   }
│   │ ]
│   ├── medical_disclaimer: "Consult healthcare..."
```

**Acceptance Criteria:**
- Citation model created
- EducationalResource extended with citations
- Firestore schema updated
- Backward compatibility maintained
- ViewModels updated

---

### Story 7.4: Update Article Detail View
**As a** user,
**I want to** see scientific citations in article detail view,
**So that** I can verify the research backing the content

**Tasks:**
- Add Citations section to EducationalResourceDetailView
- Display citations in APA format
- Make citations tappable to open source URL
- Add "References" header section
- Style citations consistently

**UI Components:**
```swift
// Citation Row Component
struct CitationRowView: View {
    let citation: Citation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // APA format display
            Text(citation.formattedAPA)
                .font(.footnote)

            if let url = citation.url {
                Link("View Source", destination: URL(string: url)!)
                    .font(.caption)
            }
        }
    }
}
```

**Acceptance Criteria:**
- Citations displayed in article detail
- APA formatting correct
- Tappable links to sources
- Responsive layout
- Accessibility labels

---

### Story 7.5: Add Citations to Settings FAQ
**As a** user,
**I want to** access all scientific citations in Settings FAQ,
**So that** I can review research sources in one place

**Tasks:**
- Create "Scientific References" section in Settings
- Fetch all citations from all articles
- Display organized by article/category
- Add search/filter functionality
- Link back to source articles

**Settings FAQ Structure:**
```
Settings > FAQ > Scientific References
├── By Category
│   ├── Science (12 citations)
│   ├── Safety (8 citations)
│   ├── Progression (6 citations)
│   └── Technique (4 citations)
├── By Article
│   ├── "PE Training Fundamentals" (5 citations)
│   └── ...
└── Search Citations
```

**Acceptance Criteria:**
- Scientific References section in Settings
- All citations accessible
- Organized by category and article
- Search functionality
- Links to source articles

---

### Story 7.6: Create Content Deployment Scripts
**As a** developer,
**I want to** create scripts to deploy articles to Firestore,
**So that** content can be easily updated and maintained

**Tasks:**
- Create article JSON schema
- Build deployment script for Firestore
- Add validation for required fields
- Support batch uploads
- Create backup/rollback mechanism

**Deployment Script:**
```javascript
// deploy-educational-articles.js
const articles = [
  {
    title: "PE Training Fundamentals: What the Science Says",
    content_text: "...",
    category: "Science",
    citations: [
      {
        id: "citation1",
        authors: "Smith, J., & Jones, A.",
        year: "2023",
        // ...
      }
    ],
    medical_disclaimer: "Always consult healthcare provider...",
    local_image_name: "article_fundamentals"
  },
  // ... 7 more articles
];

// Deploy to Firestore
deployArticles(articles, { validate: true, backup: true });
```

**Acceptance Criteria:**
- Deployment script created
- JSON schema validation
- Batch upload support
- Backup mechanism
- Deployment documentation

---

### Story 7.7: Content Review and QA
**As a** content reviewer,
**I want to** review all articles for accuracy and safety,
**So that** users receive trustworthy information

**Tasks:**
- Medical/safety review of all 8 articles
- Verify all citations are accurate
- Check citation URLs are accessible
- Ensure disclaimers are prominent
- Test article display on various devices
- Proofread for grammar/clarity

**Review Checklist:**
- [ ] Medical accuracy verified
- [ ] Safety warnings prominent
- [ ] Citations verified and accessible
- [ ] Disclaimers present
- [ ] Grammar and clarity checked
- [ ] Mobile/tablet display tested
- [ ] Accessibility compliance

**Acceptance Criteria:**
- All articles reviewed
- Citations verified
- Safety approved
- No accessibility issues
- Content approved for production

---

### Story 7.8: Deploy to Production
**As a** developer,
**I want to** deploy articles to production Firestore,
**So that** users can access the content

**Tasks:**
- Deploy articles to production `educational_resources` collection
- Verify Firestore indexes support citation queries
- Update Firestore security rules if needed
- Monitor deployment
- Create rollback plan

**Deployment Steps:**
```bash
# 1. Validate articles
node scripts/validate-articles.js

# 2. Deploy to staging first
firebase use growth-training-app
firebase firestore:deploy --collection educational_resources --env staging

# 3. Test in staging
npm run test:educational-resources

# 4. Deploy to production
firebase firestore:deploy --collection educational_resources --env production

# 5. Verify
firebase firestore:get educational_resources --limit 10
```

**Acceptance Criteria:**
- Articles deployed to production
- Indexes functional
- Security rules updated
- Deployment verified
- Rollback plan documented

---

## Technical Architecture

### Data Model
```
EducationalResource (Firestore: educational_resources)
├── id: string (DocumentID)
├── title: string
├── content_text: string
├── category: "Basics" | "Technique" | "Science" | "Safety" | "Progression"
├── citations: Citation[]
├── medical_disclaimer: string
├── visual_placeholder_url: string?
├── local_image_name: string?
└── created_at: Timestamp

Citation (embedded in EducationalResource)
├── id: string
├── authors: string
├── year: string
├── title: string
├── journal: string
├── volume: string?
├── pages: string?
├── doi: string?
└── url: string?
```

### Firestore Collection Structure
```
/educational_resources
  /{articleId}
    - title
    - content_text
    - category
    - citations[]
    - medical_disclaimer
    - local_image_name
    - created_at
```

### iOS Implementation
```
Growth/Features/EducationalResources/
├── Models/
│   ├── EducationalResource.swift (extend with citations)
│   └── Citation.swift (new model)
├── ViewModels/
│   ├── EducationalResourcesListViewModel.swift
│   ├── EducationalResourceDetailViewModel.swift (update for citations)
│   └── CitationsViewModel.swift (new for Settings)
├── Views/
│   ├── EducationalResourcesListView.swift
│   ├── EducationalResourceDetailView.swift (add citations section)
│   ├── CitationRowView.swift (new component)
│   └── ScientificReferencesView.swift (new Settings view)
└── Services/
    └── EducationalResourceService.swift (update for citations)
```

## Content Guidelines

### Article Structure
Each article should follow this template:
```markdown
# {Title}

## Overview
Brief introduction (2-3 paragraphs)

## Key Concepts
Main content sections with headers

## Scientific Evidence
Research findings with inline citations [1]

## Safety Considerations
Prominent safety warnings

## Practical Application
How to apply the information

## Medical Disclaimer
Standard disclaimer text

## References
1. Smith, J., & Jones, A. (2023). Study title. Journal Name, 12(3), 45-67. doi:10.1234/example
```

### Citation Format (APA 7th Edition)
- **Journal Article**: Author, A. A. (Year). Title of article. *Title of Periodical*, *volume*(issue), pages. doi:xx.xxxx/xxxxx
- **Website**: Author, A. A. (Year, Month Day). Title. Site Name. URL
- **Book Chapter**: Author, A. A. (Year). Chapter title. In B. B. Editor (Ed.), *Book title* (pp. xxx-xxx). Publisher.

### Safety-First Requirements
- All articles must include medical disclaimer
- Safety warnings must be prominent and visible
- Avoid definitive medical claims
- Encourage professional medical consultation
- Highlight potential risks and contraindications

## Testing Strategy

### Functional Testing
- [ ] Articles display correctly in list view
- [ ] Article detail shows content and citations
- [ ] Citation links open correctly
- [ ] Settings FAQ displays all citations
- [ ] Search/filter works in FAQ
- [ ] Medical disclaimers visible

### Content Testing
- [ ] All citations verified
- [ ] Links accessible
- [ ] APA formatting correct
- [ ] Medical accuracy confirmed
- [ ] Safety warnings prominent

### Performance Testing
- [ ] Firestore queries optimized
- [ ] Image loading performant
- [ ] Citation rendering fast
- [ ] No memory leaks

## Deployment Strategy

### Phase 1: Content Extraction (Days 1-2)
- Story 7.1: Reddit Content Scraping and Research
- Story 7.2: AI-Assisted Article Writing from Scraped Data

### Phase 2: Data Model & Backend (Day 3)
- Story 7.3: Extend EducationalResource Model

### Phase 3: Frontend Implementation (Days 4-5)
- Story 7.4: Update Article Detail View
- Story 7.5: Add Citations to Settings FAQ

### Phase 4: Deployment & QA (Days 6-7)
- Story 7.6: Create Content Deployment Scripts
- Story 7.7: Content Review and QA
- Story 7.8: Deploy to Production
- Final QA and monitoring

## Risks & Mitigations

**Risk**: Reddit API rate limiting during scraping
- **Mitigation**: Implement 2-second delays between requests, use PRAW library properly, scrape during off-peak hours

**Risk**: Scraped content quality varies (spam, misinformation)
- **Mitigation**: Filter by upvote count (>10), focus on wiki content, verify citations against actual academic sources

**Risk**: Scientific citations from Reddit may not be properly formatted
- **Mitigation**: Verify all URLs, extract proper metadata from source papers, use AI to reformat into APA 7th edition

**Risk**: Citation URLs become broken over time
- **Mitigation**: Include DOI when available (permanent), periodic link validation

**Risk**: Medical/legal liability from content
- **Mitigation**: Strong disclaimers, medical review, avoid definitive claims, emphasize Reddit content is community-sourced

**Risk**: Performance issues with citation data
- **Mitigation**: Firestore indexes, pagination, lazy loading

**Risk**: Content becomes outdated
- **Mitigation**: Version tracking, review schedule, update process, maintain scraper for future content refreshes

## Success Metrics

- Reddit scraper successfully extracts content from 4+ subreddits
- 10+ high-quality posts collected per article topic
- 8 articles deployed with 3-5 verified citations each
- 100% citation verification rate (all URLs accessible)
- All articles have medical disclaimers
- Zero broken citation links at deployment
- Content synthesized from multiple Reddit sources per topic
- User engagement with Learning Center increases
- Settings FAQ citation access functional

## Definition of Done

- [ ] Reddit scraper run successfully for all 8 topics
- [ ] Scraped data extracted to JSON with citations, key points, and warnings
- [ ] All 8 articles written using AI synthesis of scraped data
- [ ] Each article has 3-5 verified scientific citations in APA format
- [ ] Citation model implemented in Swift and Firestore
- [ ] Article detail view shows citations with tappable links
- [ ] Settings FAQ displays all citations organized by category
- [ ] All citation URLs verified as accessible
- [ ] Content reviewed and approved for medical accuracy
- [ ] Deployed to production Firestore
- [ ] All acceptance criteria met
- [ ] Documentation complete
