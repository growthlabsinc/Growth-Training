# Reddit Wiki Scraper Tools

Two approaches to scrape the r/TheScienceOfPE wiki and create a knowledge base of all links.

## Quick Start

### Method 1: JSON API (Recommended - Simple & Fast)

```bash
# Install dependencies
pip install requests

# Run the scraper
python scrape-reddit-wiki-json.py
```

This uses Reddit's JSON endpoint - just add `.json` to any Reddit URL to get the data.

### Method 2: Browser Automation (For Complex Pages)

```bash
# Install dependencies
pip install playwright playwright-stealth
playwright install chromium

# Run the scraper
python scrape-reddit-wiki.py
```

This uses Playwright to render the page like a real browser, useful if the JSON method fails.

## Output Files

Both scripts generate:

1. **JSON file** - Structured data with all links, categories, and metadata
2. **Markdown file** - Human-readable knowledge base with organized links

Files are timestamped: `reddit_wiki_kb_YYYYMMDD_HHMMSS.json/md`

## What Gets Extracted

- **All links** with their text and URLs
- **Categories and sections** from the wiki structure
- **External vs Reddit links** classification
- **User mentions** (u/username)
- **Subreddit references** (r/subreddit)
- **Metadata** (revision date, author, etc.)

## Troubleshooting

### If the scraper fails:

1. **403 Forbidden** - The wiki might be private
2. **429 Too Many Requests** - Add delays between requests
3. **No content found** - Try the other scraping method
4. **Authentication required** - Wiki might need Reddit login

### Manual Alternative

If automated scraping fails:
1. Open the wiki in your browser
2. Right-click → "Save Page As" → "Webpage, Complete"
3. Open the saved HTML file with the scraper
4. Or copy/paste the content into a text file

## Knowledge Base Structure

The generated knowledge base includes:

```
Categories/
├── Beginner Resources
│   ├── Essential Reading
│   ├── Safety Guidelines
│   └── Getting Started
├── Exercise Guides
│   ├── Length Exercises
│   ├── Girth Exercises
│   └── EQ Improvements
├── Scientific Studies
│   ├── Research Papers
│   ├── Medical Literature
│   └── Case Studies
└── Community Resources
    ├── Progress Logs
    ├── Routines
    └── Tools & Devices
```

## Privacy & Ethics

- These scripts only access publicly available wiki content
- No authentication or user data is collected
- Respect Reddit's Terms of Service
- Add delays between requests to avoid rate limiting
- Use the data responsibly

## Using the Knowledge Base

Once extracted, you can:

1. **Import into your app** - Use the JSON file to populate your database
2. **Reference material** - Use the Markdown as documentation
3. **Link validation** - Check which resources are still active
4. **Content migration** - Transform Reddit links into app content

## Example Usage in Code

```python
import json

# Load the knowledge base
with open('reddit_wiki_kb_20250119_120000.json', 'r') as f:
    kb = json.load(f)

# Access all external links
external_links = [
    link for link in kb['all_links']
    if link['is_external']
]

# Get links by category
beginner_links = kb['categories'].get('Beginner Resources', {}).get('links', [])

# Find specific topics
safety_links = [
    link for link in kb['all_links']
    if 'safety' in link['text'].lower()
]
```

## Manual Inspection

The Markdown output makes it easy to:
- Review all extracted links
- Verify categories are correct
- Identify important resources
- Plan content migration

## Next Steps

After scraping:
1. Review the extracted links in the Markdown file
2. Identify which resources to incorporate into your app
3. Create a content migration plan
4. Consider reaching out to content creators for permission
5. Transform external links into in-app educational content