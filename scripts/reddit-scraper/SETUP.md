# Reddit Scraper Setup Guide

## Story 7.1: Reddit Content Scraping and Research

This guide walks you through setting up and running the Reddit scraper to extract educational content for article creation.

## Step 1: Get Reddit API Credentials

1. Go to https://www.reddit.com/prefs/apps
2. Scroll to bottom and click "create another app..."
3. Fill in the form:
   - **name**: GrowthLabs Education Scraper
   - **type**: Select "script"
   - **description**: Scraper for educational PE content
   - **about url**: (leave blank)
   - **redirect uri**: http://localhost:8080
4. Click "create app"
5. Note your credentials:
   - **client_id**: The string under "personal use script" (14 characters)
   - **client_secret**: The "secret" field (27 characters)

## Step 2: Configure Environment Variables

1. Copy the example env file:
   ```bash
   cd scripts/reddit-scraper
   cp .env.example .env
   ```

2. Edit `.env` and add your credentials:
   ```bash
   REDDIT_CLIENT_ID=your-actual-client-id
   REDDIT_CLIENT_SECRET=your-actual-secret
   REDDIT_USER_AGENT=GrowthLabs_Education_Scraper/1.0
   TARGET_SUBREDDITS=thescienceofpe,gettingbigger,ajelqforyou
   ```

## Step 3: Install Python Dependencies

```bash
cd scripts/reddit-scraper

# Install dependencies
pip3 install -r requirements-reddit-scraper.txt

# Or install individually:
pip3 install praw==7.7.1
pip3 install python-dotenv==1.0.0
```

## Step 4: Run the Educational Content Scraper

```bash
# From the reddit-scraper directory:
python3 scrape_educational_articles.py
```

### Expected Output

The scraper will:
- Extract content from r/TheScienceOfPE, r/GettingBigger, r/AJelqForYou
- Search for posts matching 8 predefined article topics
- Extract scientific mentions (study references, research claims)
- Capture key points, warnings, and safety information
- Extract URLs to academic sources (PubMed, DOI links, etc.)

### Output File

Results saved to: `extracted_data/educational_content_raw.json`

### Data Structure

```json
{
  "science_of_tissue_expansion": {
    "posts": [...],
    "wiki_content": [...],
    "scientific_mentions": [...],
    "key_points": [...],
    "warnings": [...],
    "citations": [...]
  },
  "understanding_eq_blood_flow": { ... },
  ...
}
```

## Step 5: Review Scraped Data

After scraping completes:

1. Check `extracted_data/educational_content_raw.json`
2. Verify you have content for all 8 topics:
   - `science_of_tissue_expansion`
   - `understanding_eq_blood_flow`
   - `injury_prevention_recovery`
   - `beginner_fundamentals`
   - `heat_application_benefits`
   - `measuring_tracking_progress`
   - `supplements_nutrition`
   - `rest_recovery_decon`

3. Review the quality:
   - At least 10+ posts per topic
   - Scientific mentions extracted
   - Citations (URLs) captured
   - Key points and warnings present

## Troubleshooting

### Rate Limiting
If you encounter rate limiting errors:
- The scraper includes 2-second delays between requests
- Reddit allows 60 requests/minute
- Wait a few minutes and try again

### No Content Found
If specific topics have no content:
- Check the subreddit names in `TARGET_SUBREDDITS`
- Verify your credentials are correct
- Some subreddits may be private or restricted

### Authentication Errors
- Double-check your client_id and client_secret
- Ensure you created a "script" type app, not "web app"
- Verify the .env file is in the correct directory

## Next Steps

After successful scraping:
- ✅ Mark Story 7.1 complete
- ➡️ Proceed to Story 7.2: AI-Assisted Article Writing
- Use the scraped data to generate 8 comprehensive articles with Claude AI
