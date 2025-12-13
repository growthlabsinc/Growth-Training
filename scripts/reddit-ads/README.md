# Reddit Ads API Client for Growth Training

This directory contains scripts to manage Reddit advertising campaigns for the Growth Training iOS app via the Reddit Ads API v3.

## Prerequisites

1. **Reddit Ads Account**: You must have an active Reddit Ads account at https://ads.reddit.com
2. **Developer Application**: The `GrowthLabs_PE_Scraper` application is already registered
3. **Payment Method**: A valid payment method must be configured in Reddit Ads Manager
4. **Python 3.8+**: Required for running the scripts

## Setup

### 1. Install Dependencies

```bash
cd scripts/reddit-ads
pip3 install -r requirements.txt
```

### 2. Verify Environment

The `.env` file should already contain the correct credentials:
- `REDDIT_CLIENT_ID`: Your Reddit developer app ID
- `REDDIT_CLIENT_SECRET`: Your Reddit developer app secret
- `GROWTH_TRAINING_APP_ID`: The App Store ID for Growth Training

### 3. Run OAuth Authentication

```bash
python3 reddit_ads_api.py auth
```

This will:
1. Open your browser to Reddit's authorization page
2. Ask you to authorize the application
3. Capture the authorization callback
4. Exchange the code for access tokens
5. Save tokens to `.reddit_ads_tokens.json`

**Note**: Tokens expire after 1 hour but the script will automatically refresh them using the refresh token.

## Usage

### Discover Account Information

```bash
python3 reddit_ads_api.py accounts
```

This retrieves:
- Profile ID
- Business ID
- Ad Account ID
- Funding Instrument ID

### List Existing Campaigns

```bash
python3 reddit_ads_api.py campaigns
```

### Create Complete Campaign Setup

```bash
python3 reddit_ads_api.py create-all
```

This creates (all in PAUSED status):
1. **Campaign**: "Growth Training - PE Accountability App - Q4 2024"
   - Objective: APP_INSTALLS
   - Daily budget: $15
   - Lifetime cap: $500
   - Bid strategy: MAXIMIZE_VOLUME (CPC)

2. **Ad Group**: "PE Communities - Personal Story Angle"
   - Targeting: iOS devices only
   - Geography: US, CA, GB, AU
   - Gender: Male
   - Age: 25-54
   - Communities: r/GettingBigger, r/TheScienceOfPE, r/AJelqForYou
   - Placements: Feed and Conversation

3. **Ad**: "Personal Story - Accountability Focus"
   - Type: Freeform text (native post style)
   - Comments: Enabled
   - CTA: Learn More

### Search Available Communities

```bash
# Search for PE-related communities
python3 reddit_ads_api.py communities "getting bigger"
python3 reddit_ads_api.py communities "fitness"
```

## Campaign Configuration

The campaign is configured based on the marketing strategy in `docs/marketing/REDDIT_ADS_CAMPAIGN_STRUCTURE.md`:

### Budget
- **Testing Phase**: $15/day
- **Lifetime Cap**: $500 for initial testing

### Targeting
- **Primary**: PE-specific subreddits (mod-approved communities)
- **Secondary**: Men's health/fitness subreddits
- **Device**: iOS only (app is iOS exclusive)
- **Age**: 25-54 (core PE demographic)
- **Geography**: English-speaking markets

### Creative Strategy
- **Format**: Freeform text ads (native Reddit style)
- **Tone**: Personal story, authentic, not promotional
- **CTA**: Learn More (drives to App Store)

## Files Created

After running the scripts:

```
scripts/reddit-ads/
├── .env                          # API credentials
├── .reddit_ads_tokens.json       # OAuth tokens (auto-generated)
├── .reddit_ads_account_info.json # Account IDs (auto-generated)
├── reddit_ads_api.py             # Main API client
├── requirements.txt              # Python dependencies
└── README.md                     # This file
```

## Important Notes

### App Install Campaign Limits (as of May 5, 2024)
- Max 10 campaigns per app ID (across all ad accounts)
- Max 5 ad groups per campaign
- Max 10 ads per ad group

### Before Activating
1. Review all settings in Reddit Ads Manager
2. Verify payment method is configured
3. Upload any image assets needed
4. Test tracking links
5. Set up UTM parameters for attribution

### Monitoring
- Check performance daily during first week
- Pause ads with CTR < 0.2%
- Monitor comments for feedback
- Track App Store installs via App Store Connect

## Troubleshooting

### "No ad account found"
You need to create an ad account in Reddit Ads Manager first:
1. Go to https://ads.reddit.com
2. Complete business setup
3. Create an ad account

### "No funding instrument found"
Add a payment method in Reddit Ads Manager:
1. Go to https://ads.reddit.com
2. Navigate to Billing
3. Add a credit card or other payment method

### "Token expired"
Tokens auto-refresh, but if issues persist:
```bash
python3 reddit_ads_api.py auth
```

### Rate Limiting
Reddit Ads API has rate limits. If you hit them:
- Wait a few minutes
- The script includes automatic retry logic

## Support

For Reddit Ads API issues:
- Reddit Ads Help: https://business.reddithelp.com
- API Documentation: https://ads-api.reddit.com/docs/v3

For Growth Training app issues:
- Contact: jon@growthlabs.coach
