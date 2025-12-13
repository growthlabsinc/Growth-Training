#!/usr/bin/env python3
"""
Reddit Ads API Client for Growth Training App

This script handles OAuth authentication and campaign management
for Reddit Ads API v3.

Usage:
1. Run the OAuth flow: python reddit_ads_api.py auth
2. Get ad account info: python reddit_ads_api.py accounts
3. Create campaign: python reddit_ads_api.py create-campaign
"""

import os
import sys
import json
import time
import csv
import webbrowser
import http.server
import socketserver
import urllib.parse
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, Optional, Any, List
import requests
from dotenv import load_dotenv

# Load environment variables
env_path = Path(__file__).parent / '.env'
load_dotenv(env_path)

# Reddit Ads API Configuration
REDDIT_ADS_CONFIG = {
    'client_id': os.getenv('REDDIT_CLIENT_ID', 'uP_-CGdtleId7F8n8fjsCA'),
    'client_secret': os.getenv('REDDIT_CLIENT_SECRET', 'TUi0MEL9fmcOd9ucLWI2tGAwpS8s4g'),
    'redirect_uri': os.getenv('REDDIT_REDIRECT_URI', 'http://localhost:8080'),
    'user_agent': 'GrowthLabs_PE_Scraper/1.0 (by /u/growthlabs)',
}

# API Endpoints
REDDIT_AUTH_URL = 'https://www.reddit.com/api/v1/authorize'
REDDIT_TOKEN_URL = 'https://www.reddit.com/api/v1/access_token'
REDDIT_ADS_API_BASE = 'https://ads-api.reddit.com/api/v3'

# Token storage file
TOKEN_FILE = Path(__file__).parent / '.reddit_ads_tokens.json'

# Required OAuth scopes for Ads API
# adsread - Read ad account data
# adsedit - Write/edit ad account data (create campaigns, ads, etc.)
# adsconversions - Access conversion data
# history - Access user history
# read - Read user data
# identity - User identity
# Note: submit scope requires a separate standard Reddit app, not the Ads API app
OAUTH_SCOPES = 'adsread adsedit adsconversions history read identity'


class RedditAdsAuth:
    """Handle OAuth authentication for Reddit Ads API."""

    def __init__(self):
        self.config = REDDIT_ADS_CONFIG
        self.access_token = None
        self.refresh_token = None
        self.token_expiry = None
        self.load_tokens()

    def load_tokens(self) -> bool:
        """Load saved tokens from file."""
        if TOKEN_FILE.exists():
            try:
                with open(TOKEN_FILE, 'r') as f:
                    data = json.load(f)
                self.access_token = data.get('access_token')
                self.refresh_token = data.get('refresh_token')
                expiry = data.get('token_expiry')
                if expiry:
                    self.token_expiry = datetime.fromisoformat(expiry)
                print(f"[INFO] Loaded tokens from {TOKEN_FILE}")
                return True
            except Exception as e:
                print(f"[WARN] Failed to load tokens: {e}")
        return False

    def save_tokens(self):
        """Save tokens to file."""
        data = {
            'access_token': self.access_token,
            'refresh_token': self.refresh_token,
            'token_expiry': self.token_expiry.isoformat() if self.token_expiry else None,
            'updated_at': datetime.now().isoformat()
        }
        with open(TOKEN_FILE, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"[INFO] Saved tokens to {TOKEN_FILE}")

    def is_token_valid(self) -> bool:
        """Check if current access token is valid."""
        if not self.access_token or not self.token_expiry:
            return False
        # Consider token invalid if it expires within 5 minutes
        return datetime.now() < (self.token_expiry - timedelta(minutes=5))

    def get_authorization_url(self) -> str:
        """Generate OAuth authorization URL."""
        import secrets
        state = secrets.token_urlsafe(16)

        params = {
            'client_id': self.config['client_id'],
            'response_type': 'code',
            'state': state,
            'redirect_uri': self.config['redirect_uri'],
            'duration': 'permanent',  # Get refresh token
            'scope': OAUTH_SCOPES
        }

        url = f"{REDDIT_AUTH_URL}?{urllib.parse.urlencode(params)}"
        return url, state

    def exchange_code_for_token(self, code: str) -> Dict:
        """Exchange authorization code for access token."""
        data = {
            'grant_type': 'authorization_code',
            'code': code,
            'redirect_uri': self.config['redirect_uri']
        }

        response = requests.post(
            REDDIT_TOKEN_URL,
            data=data,
            auth=(self.config['client_id'], self.config['client_secret']),
            headers={
                'User-Agent': self.config['user_agent'],
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        )

        if response.status_code != 200:
            raise Exception(f"Token exchange failed: {response.status_code} - {response.text}")

        token_data = response.json()

        self.access_token = token_data.get('access_token')
        self.refresh_token = token_data.get('refresh_token')
        self.token_expiry = datetime.now() + timedelta(seconds=token_data.get('expires_in', 3600))

        self.save_tokens()

        return token_data

    def refresh_access_token(self) -> Dict:
        """Refresh the access token using refresh token."""
        if not self.refresh_token:
            raise Exception("No refresh token available. Run OAuth flow first.")

        data = {
            'grant_type': 'refresh_token',
            'refresh_token': self.refresh_token
        }

        response = requests.post(
            REDDIT_TOKEN_URL,
            data=data,
            auth=(self.config['client_id'], self.config['client_secret']),
            headers={
                'User-Agent': self.config['user_agent'],
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        )

        if response.status_code != 200:
            raise Exception(f"Token refresh failed: {response.status_code} - {response.text}")

        token_data = response.json()

        self.access_token = token_data.get('access_token')
        self.token_expiry = datetime.now() + timedelta(seconds=token_data.get('expires_in', 3600))

        # Keep existing refresh token if not provided in response
        if token_data.get('refresh_token'):
            self.refresh_token = token_data['refresh_token']

        self.save_tokens()

        return token_data

    def get_valid_token(self) -> str:
        """Get a valid access token, refreshing if necessary."""
        if self.is_token_valid():
            return self.access_token

        if self.refresh_token:
            print("[INFO] Token expired, refreshing...")
            self.refresh_access_token()
            return self.access_token

        raise Exception("No valid token available. Run OAuth flow first.")

    def run_oauth_flow(self):
        """Run the complete OAuth flow with local server for callback."""
        auth_url, state = self.get_authorization_url()

        print("\n" + "="*60)
        print("REDDIT ADS API OAUTH AUTHENTICATION")
        print("="*60)
        print("\n1. Opening browser for Reddit authorization...")
        print(f"\nAuthorization URL:\n{auth_url}\n")

        # Start local server to capture callback
        received_code = {'code': None, 'state': None}

        class CallbackHandler(http.server.SimpleHTTPRequestHandler):
            def do_GET(self):
                parsed = urllib.parse.urlparse(self.path)
                if parsed.path in ['/', '/callback', '']:
                    params = urllib.parse.parse_qs(parsed.query)
                    received_code['code'] = params.get('code', [None])[0]
                    received_code['state'] = params.get('state', [None])[0]

                    self.send_response(200)
                    self.send_header('Content-type', 'text/html')
                    self.end_headers()

                    html = """
                    <html><body>
                    <h1>Authorization Successful!</h1>
                    <p>You can close this window and return to the terminal.</p>
                    <script>setTimeout(function(){ window.close(); }, 3000);</script>
                    </body></html>
                    """
                    self.wfile.write(html.encode())
                else:
                    self.send_response(404)
                    self.end_headers()

            def log_message(self, format, *args):
                pass  # Suppress logging

        # Open browser
        webbrowser.open(auth_url)

        print("2. Waiting for authorization callback on localhost:8080...")
        print("   (Authorize the app in your browser)\n")

        # Start server and wait for callback
        # Enable socket reuse to avoid "Address already in use" errors
        class ReusableTCPServer(socketserver.TCPServer):
            allow_reuse_address = True

        with ReusableTCPServer(("", 8080), CallbackHandler) as httpd:
            httpd.handle_request()

        if not received_code['code']:
            raise Exception("No authorization code received")

        if received_code['state'] != state:
            raise Exception("State mismatch - possible CSRF attack")

        print("3. Authorization code received, exchanging for tokens...")

        token_data = self.exchange_code_for_token(received_code['code'])

        print("\n" + "="*60)
        print("AUTHENTICATION SUCCESSFUL!")
        print("="*60)
        print(f"\nAccess Token: {self.access_token[:20]}...")
        print(f"Refresh Token: {self.refresh_token[:20] if self.refresh_token else 'None'}...")
        print(f"Expires: {self.token_expiry}")
        print(f"\nTokens saved to: {TOKEN_FILE}")

        return token_data


class RedditAdsClient:
    """Client for Reddit Ads API v3."""

    def __init__(self, auth: RedditAdsAuth):
        self.auth = auth
        self.base_url = REDDIT_ADS_API_BASE

    def _get_headers(self) -> Dict[str, str]:
        """Get headers for API requests."""
        return {
            'Authorization': f'Bearer {self.auth.get_valid_token()}',
            'Content-Type': 'application/json',
            'User-Agent': REDDIT_ADS_CONFIG['user_agent']
        }

    def _request(self, method: str, endpoint: str, data: Optional[Dict] = None) -> Dict:
        """Make an API request."""
        url = f"{self.base_url}{endpoint}"

        response = requests.request(
            method=method,
            url=url,
            headers=self._get_headers(),
            json=data if data else None
        )

        print(f"[DEBUG] {method} {url} -> {response.status_code}")

        if response.status_code not in [200, 201]:
            print(f"[ERROR] Response: {response.text}")
            raise Exception(f"API request failed: {response.status_code} - {response.text}")

        return response.json()

    # ==================== Account Management ====================

    def get_me(self) -> Dict:
        """Get current user's profile."""
        return self._request('GET', '/me')

    def get_profile(self, profile_id: str) -> Dict:
        """Get profile by ID."""
        return self._request('GET', f'/profiles/{profile_id}')

    def get_businesses(self) -> Dict:
        """Get businesses for current user."""
        return self._request('GET', '/me/businesses')

    def get_ad_accounts(self, business_id: str) -> Dict:
        """Get ad accounts for a business."""
        return self._request('GET', f'/businesses/{business_id}/ad_accounts')

    def get_ad_account(self, ad_account_id: str) -> Dict:
        """Get a specific ad account."""
        return self._request('GET', f'/ad_accounts/{ad_account_id}')

    def get_funding_instruments(self, ad_account_id: str) -> Dict:
        """Get funding instruments for an ad account."""
        return self._request('GET', f'/ad_accounts/{ad_account_id}/funding_instruments')

    # ==================== Campaign Management ====================

    def get_campaigns(self, ad_account_id: str) -> Dict:
        """Get all campaigns for an ad account."""
        return self._request('GET', f'/ad_accounts/{ad_account_id}/campaigns')

    def get_campaign(self, ad_account_id: str, campaign_id: str) -> Dict:
        """Get a specific campaign."""
        return self._request('GET', f'/ad_accounts/{ad_account_id}/campaigns/{campaign_id}')

    def create_campaign(self, ad_account_id: str, campaign_data: Dict) -> Dict:
        """
        Create a new campaign.

        Args:
            ad_account_id: The ad account ID
            campaign_data: Campaign configuration

        Returns:
            Created campaign data
        """
        return self._request('POST', f'/ad_accounts/{ad_account_id}/campaigns', {'data': campaign_data})

    def update_campaign(self, ad_account_id: str, campaign_id: str, campaign_data: Dict) -> Dict:
        """Update an existing campaign."""
        return self._request('PUT', f'/ad_accounts/{ad_account_id}/campaigns/{campaign_id}', {'data': campaign_data})

    # ==================== Ad Group Management ====================

    def get_ad_groups(self, ad_account_id: str) -> Dict:
        """Get all ad groups for an ad account."""
        return self._request('GET', f'/ad_accounts/{ad_account_id}/ad_groups')

    def create_ad_group(self, ad_account_id: str, ad_group_data: Dict) -> Dict:
        """
        Create a new ad group.

        Args:
            ad_account_id: The ad account ID
            ad_group_data: Ad group configuration

        Returns:
            Created ad group data
        """
        return self._request('POST', f'/ad_accounts/{ad_account_id}/ad_groups', {'data': ad_group_data})

    # ==================== Ad Management ====================

    def get_ads(self, ad_account_id: str) -> Dict:
        """Get all ads for an ad account."""
        return self._request('GET', f'/ad_accounts/{ad_account_id}/ads')

    def create_ad(self, ad_account_id: str, ad_data: Dict) -> Dict:
        """
        Create a new ad.

        Args:
            ad_account_id: The ad account ID
            ad_data: Ad configuration

        Returns:
            Created ad data
        """
        return self._request('POST', f'/ad_accounts/{ad_account_id}/ads', {'data': ad_data})

    def update_ad(self, ad_id: str, ad_data: Dict) -> Dict:
        """
        Update an existing ad.

        Args:
            ad_id: The ad ID to update
            ad_data: Updated ad configuration

        Returns:
            Updated ad data
        """
        return self._request('PATCH', f'/ads/{ad_id}', {'data': ad_data})

    def get_ad(self, ad_id: str) -> Dict:
        """Get a specific ad by ID."""
        return self._request('GET', f'/ads/{ad_id}')

    # ==================== Targeting ====================

    def get_communities(self, query: Optional[str] = None) -> Dict:
        """Get available communities (subreddits) for targeting."""
        endpoint = '/targeting/communities'
        if query:
            endpoint += f'?q={urllib.parse.quote(query)}'
        return self._request('GET', endpoint)

    def get_interests(self) -> Dict:
        """Get available interests for targeting."""
        return self._request('GET', '/targeting/interests')

    def get_geolocations(self, query: Optional[str] = None) -> Dict:
        """Get available geolocations for targeting."""
        endpoint = '/targeting/geolocations'
        if query:
            endpoint += f'?q={urllib.parse.quote(query)}'
        return self._request('GET', endpoint)


def discover_account_info(client: RedditAdsClient):
    """Discover and print account information."""
    print("\n" + "="*60)
    print("DISCOVERING ACCOUNT INFORMATION")
    print("="*60)

    # Step 1: Get profile
    print("\n1. Getting profile...")
    me = client.get_me()
    print(f"   Profile ID: {me.get('data', {}).get('id')}")
    profile_id = me.get('data', {}).get('id')

    # Step 2: Get businesses
    print("\n2. Getting businesses...")
    businesses = client.get_businesses()
    for biz in businesses.get('data', []):
        print(f"   Business: {biz.get('name')} (ID: {biz.get('id')})")

    business_id = businesses.get('data', [{}])[0].get('id') if businesses.get('data') else None

    if not business_id:
        print("\n[WARN] No business found. You may need to create one in Reddit Ads Manager.")
        return None, None

    # Step 3: Get ad accounts
    print("\n3. Getting ad accounts...")
    ad_accounts = client.get_ad_accounts(business_id)
    for acc in ad_accounts.get('data', []):
        print(f"   Ad Account: {acc.get('name')} (ID: {acc.get('id')})")
        print(f"      Status: {acc.get('status')}")
        print(f"      Currency: {acc.get('currency')}")

    ad_account_id = ad_accounts.get('data', [{}])[0].get('id') if ad_accounts.get('data') else None

    if not ad_account_id:
        print("\n[WARN] No ad account found. You may need to create one in Reddit Ads Manager.")
        return business_id, None

    # Step 4: Get funding instruments
    print("\n4. Getting funding instruments...")
    funding = client.get_funding_instruments(ad_account_id)
    for fi in funding.get('data', []):
        print(f"   Funding: {fi.get('type')} (ID: {fi.get('id')})")
        print(f"      Status: {fi.get('status')}")

    funding_id = funding.get('data', [{}])[0].get('id') if funding.get('data') else None

    # Save account info
    account_info = {
        'profile_id': profile_id,
        'business_id': business_id,
        'ad_account_id': ad_account_id,
        'funding_instrument_id': funding_id,
        'discovered_at': datetime.now().isoformat()
    }

    info_file = Path(__file__).parent / '.reddit_ads_account_info.json'
    with open(info_file, 'w') as f:
        json.dump(account_info, f, indent=2)
    print(f"\n[INFO] Account info saved to {info_file}")

    return ad_account_id, funding_id


def generate_bulk_csv(client: RedditAdsClient, ad_account_id: str, output_file: str = 'reddit_ads_bulk.csv'):
    """Generate a bulk import CSV for creating new ads."""

    print("\n" + "="*60)
    print("GENERATING BULK IMPORT CSV")
    print("="*60)

    # Get existing campaigns and ad groups
    campaigns = client.get_campaigns(ad_account_id)
    ad_groups = client.get_ad_groups(ad_account_id)

    # CSV headers matching Reddit's bulk import template
    headers = [
        'Results', 'Campaign ID', 'Campaign name', 'Special ad category', 'Campaign objective',
        'Campaign budget', 'Funding instrument', 'Campaign status', 'Campaign App ID',
        'Ad group ID', 'Ad group name', 'Start time', 'End time', 'Bid strategy', 'Bid',
        'Budget type', 'Budget', 'Conversion goal', 'Conversion optimization window',
        'Frequency caps', 'Ad group status', 'Locations', 'Exclude locations', 'Gender',
        'Exclude keywords', 'Keywords', 'Interests', 'Communities', 'Exclude communities',
        'Auto app exclusions', 'Device type', 'Minimum OS version', 'Carriers', 'Placements',
        'Platforms', 'Custom audiences', 'Exclude custom audiences', 'Third-party audiences',
        'Exclude third-party audiences', 'Expand audience automatically', 'Delivery type',
        'Ad Group App ID', 'Shopping Ad Type', 'Product Catalog ID', 'Ad ID', 'Ad name',
        'Impression trackers', 'Click trackers', 'Ad status', 'Second Line CTA', 'Ad product IDs',
        'Post ID', 'Profile name or ID', 'Post type', 'Call to action', 'Headline',
        'Destination URL', 'Display URL', 'Media file name', 'Thumbnail file name', 'Body',
        'Allow comments', 'Additional Text'
    ]

    rows = []

    # Example: Create new ads for existing campaign/ad group
    # This is a template - modify the ad variations as needed
    ad_variations = [
        {
            'name': 'Personal Story - Accountability Focus',
            'headline': 'After 2 years on r/GettingBigger, I built the accountability system I wish I had',
            'body': 'Fellow practitioners - I achieved real, measurable gains through consistent training. The hardest part was staying accountable. Growth Training: Lock Screen timer, proven routines, progress charts. Free trial, less than $1/week.',
            'cta': 'LEARN MORE',
            'post_type': 'TEXT'
        },
        {
            'name': 'Results Angle - Proof Focus',
            'headline': 'My PE progress: 0.5" length gain in 6 months with just 15 min/day consistency',
            'body': 'The key was never missing sessions. Built an app to keep myself accountable. Lock screen timer you can\'t ignore. Track every session. See your progress over time. Try it free.',
            'cta': 'INSTALL',
            'post_type': 'TEXT'
        },
        {
            'name': 'Science-Based Angle',
            'headline': 'Tracking my PE gains scientifically - the app I built for measurement accuracy',
            'body': 'After reading r/TheScienceOfPE, I knew measurement consistency was key. Built Growth Training to track sessions, log measurements, and follow proven routines. Your data stays private.',
            'cta': 'LEARN MORE',
            'post_type': 'TEXT'
        },
    ]

    # Get first campaign and ad group IDs (if they exist)
    campaign_id = campaigns.get('data', [{}])[0].get('id', '') if campaigns.get('data') else ''
    ad_group_id = ad_groups.get('data', [{}])[0].get('id', '') if ad_groups.get('data') else ''

    for i, ad in enumerate(ad_variations):
        row = [''] * len(headers)

        # If no existing campaign/ad group, leave blank to create new
        if campaign_id:
            row[headers.index('Campaign ID')] = f"'{campaign_id}"
        if ad_group_id:
            row[headers.index('Ad group ID')] = f"'{ad_group_id}"

        # Ad details
        row[headers.index('Ad name')] = ad['name']
        row[headers.index('Ad status')] = 'PAUSED'
        row[headers.index('Post type')] = ad['post_type']
        row[headers.index('Call to action')] = ad['cta']
        row[headers.index('Headline')] = ad['headline']
        row[headers.index('Body')] = ad['body']
        row[headers.index('Allow comments')] = 'TRUE'

        rows.append(row)

    # Write CSV
    output_path = Path(__file__).parent / output_file
    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        writer.writerows(rows)

    print(f"\n[SUCCESS] Bulk CSV created: {output_path}")
    print(f"   - {len(rows)} ad variations included")
    print(f"\nNext steps:")
    print(f"   1. Edit the CSV to customize ad variations")
    print(f"   2. Upload to Reddit Ads Manager via Import Campaign > Import from template")

    return output_path


def list_ad_groups(client: RedditAdsClient, ad_account_id: str):
    """List all ad groups for an ad account."""
    print("\n" + "="*60)
    print("AD GROUPS")
    print("="*60)

    ad_groups = client.get_ad_groups(ad_account_id)

    for ag in ad_groups.get('data', []):
        print(f"\n  Ad Group: {ag.get('name')}")
        print(f"    ID: {ag.get('id')}")
        print(f"    Campaign ID: {ag.get('campaign_id')}")
        print(f"    Status: {ag.get('effective_status')}")
        print(f"    Optimization Goal: {ag.get('optimization_goal')}")

    return ad_groups


def list_ads(client: RedditAdsClient, ad_account_id: str):
    """List all ads for an ad account."""
    print("\n" + "="*60)
    print("ADS")
    print("="*60)

    ads = client.get_ads(ad_account_id)

    for ad in ads.get('data', []):
        print(f"\n  Ad: {ad.get('name')}")
        print(f"    ID: {ad.get('id')}")
        print(f"    Ad Group ID: {ad.get('ad_group_id')}")
        print(f"    Status: {ad.get('effective_status')}")
        print(f"    Type: {ad.get('type')}")

    return ads


def export_existing_campaigns(client: RedditAdsClient, ad_account_id: str, output_file: str = 'reddit_ads_export.csv'):
    """Export existing campaigns, ad groups, and ads to CSV format."""

    print("\n" + "="*60)
    print("EXPORTING EXISTING CAMPAIGNS TO CSV")
    print("="*60)

    campaigns = client.get_campaigns(ad_account_id)
    ad_groups = client.get_ad_groups(ad_account_id)
    ads = client.get_ads(ad_account_id)

    # Create a mapping for quick lookup
    campaign_map = {c['id']: c for c in campaigns.get('data', [])}
    ad_group_map = {ag['id']: ag for ag in ad_groups.get('data', [])}

    # CSV headers
    headers = [
        'Campaign ID', 'Campaign Name', 'Campaign Status', 'Campaign Objective',
        'Ad Group ID', 'Ad Group Name', 'Ad Group Status',
        'Ad ID', 'Ad Name', 'Ad Status', 'Ad Type'
    ]

    rows = []

    for ad in ads.get('data', []):
        ad_group = ad_group_map.get(ad.get('ad_group_id'), {})
        campaign = campaign_map.get(ad_group.get('campaign_id'), {})

        row = [
            campaign.get('id', ''),
            campaign.get('name', ''),
            campaign.get('effective_status', ''),
            campaign.get('objective', ''),
            ad_group.get('id', ''),
            ad_group.get('name', ''),
            ad_group.get('effective_status', ''),
            ad.get('id', ''),
            ad.get('name', ''),
            ad.get('effective_status', ''),
            ad.get('type', '')
        ]
        rows.append(row)

    # Write CSV
    output_path = Path(__file__).parent / output_file
    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        writer.writerows(rows)

    print(f"\n[SUCCESS] Export created: {output_path}")
    print(f"   - {len(campaigns.get('data', []))} campaigns")
    print(f"   - {len(ad_groups.get('data', []))} ad groups")
    print(f"   - {len(ads.get('data', []))} ads")

    return output_path


def create_growth_training_campaign(client: RedditAdsClient, ad_account_id: str, funding_id: Optional[str] = None):
    """Create the Growth Training app install campaign."""

    print("\n" + "="*60)
    print("CREATING GROWTH TRAINING CAMPAIGN")
    print("="*60)

    # App Store ID for Growth Training
    # You'll need to replace this with your actual App Store ID
    APP_STORE_ID = os.getenv('GROWTH_TRAINING_APP_ID', '6475305599')  # Replace with actual ID

    # Campaign configuration based on our marketing plan
    campaign_data = {
        'name': 'Growth Training - PE Accountability App - Q4 2024',
        'objective': 'APP_INSTALLS',
        'configured_status': 'PAUSED',  # Start paused to review before activating
        'is_campaign_budget_optimization': True,
        'goal_type': 'DAILY_SPEND',
        'goal_value': 15000000,  # $15/day in microcurrency (15 * 1,000,000)
        'spend_cap': 500000000,  # $500 lifetime cap in microcurrency
        'bid_strategy': 'MAXIMIZE_VOLUME',
        'bid_type': 'CPC',
        'app_id': APP_STORE_ID,
        'view_through_conversion_type': 'SEVEN_DAY_CLICKS',
    }

    if funding_id:
        campaign_data['funding_instrument_id'] = funding_id

    print("\nCampaign Configuration:")
    print(json.dumps(campaign_data, indent=2))

    print("\nCreating campaign...")
    result = client.create_campaign(ad_account_id, campaign_data)

    campaign = result.get('data', {})
    campaign_id = campaign.get('id')

    print(f"\n[SUCCESS] Campaign created!")
    print(f"   Campaign ID: {campaign_id}")
    print(f"   Name: {campaign.get('name')}")
    print(f"   Status: {campaign.get('effective_status')}")

    return campaign_id, campaign


def create_pe_subreddit_ad_group(client: RedditAdsClient, ad_account_id: str, campaign_id: str):
    """Create ad group targeting PE subreddits."""

    print("\n" + "="*60)
    print("CREATING AD GROUP - PE SUBREDDITS")
    print("="*60)

    # Ad group configuration
    ad_group_data = {
        'name': 'PE Communities - Personal Story Angle',
        'campaign_id': campaign_id,
        'configured_status': 'PAUSED',
        'optimization_goal': 'APP_INSTALLS',

        # Targeting
        'targeting': {
            # Device targeting - iOS only
            'device_types': ['iOS'],

            # Geographic targeting
            'geolocations': {
                'included': [
                    {'type': 'COUNTRY', 'value': 'US'},
                    {'type': 'COUNTRY', 'value': 'CA'},
                    {'type': 'COUNTRY', 'value': 'GB'},
                    {'type': 'COUNTRY', 'value': 'AU'},
                ]
            },

            # Gender targeting
            'genders': ['MALE'],

            # Age targeting (25-49)
            'age_ranges': [
                {'min': 25, 'max': 34},
                {'min': 35, 'max': 44},
                {'min': 45, 'max': 54},
            ],

            # Community (subreddit) targeting
            'communities': {
                'included': [
                    # Note: These need to be actual community IDs
                    # You'll need to look these up via the communities endpoint
                    'gettingbigger',
                    'TheScienceOfPE',
                    'AJelqForYou',
                ]
            },

            # Expansion off for tight control
            'expansion_enabled': False,
        },

        # Scheduling
        'start_time': datetime.now().isoformat() + 'Z',

        # Placement
        'placements': ['FEED', 'CONVERSATION'],
    }

    print("\nAd Group Configuration:")
    print(json.dumps(ad_group_data, indent=2))

    print("\nCreating ad group...")
    result = client.create_ad_group(ad_account_id, ad_group_data)

    ad_group = result.get('data', {})
    ad_group_id = ad_group.get('id')

    print(f"\n[SUCCESS] Ad group created!")
    print(f"   Ad Group ID: {ad_group_id}")
    print(f"   Name: {ad_group.get('name')}")

    return ad_group_id, ad_group


def create_freeform_ad(client: RedditAdsClient, ad_account_id: str, ad_group_id: str):
    """Create freeform text ad with personal story angle."""

    print("\n" + "="*60)
    print("CREATING AD - FREEFORM TEXT (PERSONAL STORY)")
    print("="*60)

    # Ad creative based on our marketing strategy
    ad_data = {
        'name': 'Personal Story - Accountability Focus',
        'ad_group_id': ad_group_id,
        'configured_status': 'PAUSED',

        # Ad type
        'type': 'TEXT',  # Freeform text ad

        # Creative
        'headline': 'After 2 years on r/GettingBigger, I built the accountability system I wish I had',

        'body': """Fellow practitioners - I achieved real, measurable gains through consistent training.

The hardest part wasn't finding the right routine. It was staying accountable.

That's why I built Growth Training:
• Lock Screen timer keeps you accountable (can't ignore it)
• Proven routines from r/TheScienceOfPE research
• Progress charts that show proof it's working
• Anonymous, private - no one knows what you're tracking

Free trial available. Less than $1/week if it helps you stay consistent.""",

        'call_to_action': 'LEARN_MORE',

        # Destination
        'destination_url': 'https://apps.apple.com/app/growth-training/id6475305599?utm_source=reddit&utm_medium=paid&utm_campaign=pe_accountability_q4&utm_content=freeform_personal_story',

        # Comments setting
        'allow_comments': True,  # Enable for engagement
    }

    print("\nAd Configuration:")
    print(json.dumps(ad_data, indent=2))

    print("\nCreating ad...")
    result = client.create_ad(ad_account_id, ad_data)

    ad = result.get('data', {})
    ad_id = ad.get('id')

    print(f"\n[SUCCESS] Ad created!")
    print(f"   Ad ID: {ad_id}")
    print(f"   Name: {ad.get('name')}")
    print(f"   Status: {ad.get('effective_status')}")

    return ad_id, ad


def main():
    """Main entry point."""

    if len(sys.argv) < 2:
        print("""
Reddit Ads API Client for Growth Training

Usage:
    python reddit_ads_api.py auth              - Run OAuth authentication flow
    python reddit_ads_api.py accounts          - Discover and display account info
    python reddit_ads_api.py campaigns         - List existing campaigns
    python reddit_ads_api.py ad-groups         - List existing ad groups
    python reddit_ads_api.py ads               - List existing ads
    python reddit_ads_api.py export            - Export campaigns/ad groups/ads to CSV
    python reddit_ads_api.py bulk-csv          - Generate bulk import CSV template
    python reddit_ads_api.py create-campaign   - Create Growth Training campaign
    python reddit_ads_api.py create-all        - Create campaign, ad group, and ad
    python reddit_ads_api.py communities       - Search for communities to target
        """)
        return

    command = sys.argv[1]

    # Initialize auth
    auth = RedditAdsAuth()

    if command == 'auth':
        auth.run_oauth_flow()
        return

    # For other commands, we need valid auth
    if not auth.is_token_valid() and not auth.refresh_token:
        print("[ERROR] No valid authentication. Run 'python reddit_ads_api.py auth' first.")
        return

    # Initialize client
    client = RedditAdsClient(auth)

    if command == 'accounts':
        discover_account_info(client)

    elif command == 'campaigns':
        # Load account info
        info_file = Path(__file__).parent / '.reddit_ads_account_info.json'
        if not info_file.exists():
            print("[INFO] Running account discovery first...")
            discover_account_info(client)

        with open(info_file, 'r') as f:
            account_info = json.load(f)

        ad_account_id = account_info.get('ad_account_id')
        if not ad_account_id:
            print("[ERROR] No ad account ID found. Run 'accounts' command first.")
            return

        print(f"\nListing campaigns for ad account: {ad_account_id}")
        campaigns = client.get_campaigns(ad_account_id)

        for c in campaigns.get('data', []):
            print(f"\n  Campaign: {c.get('name')}")
            print(f"    ID: {c.get('id')}")
            print(f"    Objective: {c.get('objective')}")
            print(f"    Status: {c.get('effective_status')}")

    elif command == 'ad-groups':
        # Load account info
        info_file = Path(__file__).parent / '.reddit_ads_account_info.json'
        if not info_file.exists():
            print("[INFO] Running account discovery first...")
            discover_account_info(client)

        with open(info_file, 'r') as f:
            account_info = json.load(f)

        ad_account_id = account_info.get('ad_account_id')
        if not ad_account_id:
            print("[ERROR] No ad account ID found. Run 'accounts' command first.")
            return

        list_ad_groups(client, ad_account_id)

    elif command == 'ads':
        # Load account info
        info_file = Path(__file__).parent / '.reddit_ads_account_info.json'
        if not info_file.exists():
            print("[INFO] Running account discovery first...")
            discover_account_info(client)

        with open(info_file, 'r') as f:
            account_info = json.load(f)

        ad_account_id = account_info.get('ad_account_id')
        if not ad_account_id:
            print("[ERROR] No ad account ID found. Run 'accounts' command first.")
            return

        list_ads(client, ad_account_id)

    elif command == 'export':
        # Load account info
        info_file = Path(__file__).parent / '.reddit_ads_account_info.json'
        if not info_file.exists():
            print("[INFO] Running account discovery first...")
            discover_account_info(client)

        with open(info_file, 'r') as f:
            account_info = json.load(f)

        ad_account_id = account_info.get('ad_account_id')
        if not ad_account_id:
            print("[ERROR] No ad account ID found. Run 'accounts' command first.")
            return

        export_existing_campaigns(client, ad_account_id)

    elif command == 'bulk-csv':
        # Load account info
        info_file = Path(__file__).parent / '.reddit_ads_account_info.json'
        if not info_file.exists():
            print("[INFO] Running account discovery first...")
            discover_account_info(client)

        with open(info_file, 'r') as f:
            account_info = json.load(f)

        ad_account_id = account_info.get('ad_account_id')
        if not ad_account_id:
            print("[ERROR] No ad account ID found. Run 'accounts' command first.")
            return

        generate_bulk_csv(client, ad_account_id)

    elif command == 'create-campaign':
        # Load or discover account info
        info_file = Path(__file__).parent / '.reddit_ads_account_info.json'
        if not info_file.exists():
            print("[INFO] Running account discovery first...")
            ad_account_id, funding_id = discover_account_info(client)
        else:
            with open(info_file, 'r') as f:
                account_info = json.load(f)
            ad_account_id = account_info.get('ad_account_id')
            funding_id = account_info.get('funding_instrument_id')

        if not ad_account_id:
            print("[ERROR] No ad account ID found. Set up your ad account in Reddit Ads Manager first.")
            return

        create_growth_training_campaign(client, ad_account_id, funding_id)

    elif command == 'create-all':
        # Load or discover account info
        info_file = Path(__file__).parent / '.reddit_ads_account_info.json'
        if not info_file.exists():
            print("[INFO] Running account discovery first...")
            ad_account_id, funding_id = discover_account_info(client)
        else:
            with open(info_file, 'r') as f:
                account_info = json.load(f)
            ad_account_id = account_info.get('ad_account_id')
            funding_id = account_info.get('funding_instrument_id')

        if not ad_account_id:
            print("[ERROR] No ad account ID found. Set up your ad account in Reddit Ads Manager first.")
            return

        # Create campaign
        campaign_id, _ = create_growth_training_campaign(client, ad_account_id, funding_id)

        # Create ad group
        ad_group_id, _ = create_pe_subreddit_ad_group(client, ad_account_id, campaign_id)

        # Create ad
        ad_id, _ = create_freeform_ad(client, ad_account_id, ad_group_id)

        print("\n" + "="*60)
        print("CAMPAIGN CREATION COMPLETE!")
        print("="*60)
        print(f"""
Campaign, Ad Group, and Ad have been created in PAUSED status.

Next Steps:
1. Log into Reddit Ads Manager: https://ads.reddit.com
2. Review the campaign settings
3. Add payment method if not already configured
4. Upload any image assets for image ads
5. Activate the campaign when ready

Created Resources:
- Campaign ID: {campaign_id}
- Ad Group ID: {ad_group_id}
- Ad ID: {ad_id}
        """)

    elif command == 'communities':
        query = sys.argv[2] if len(sys.argv) > 2 else None
        print(f"\nSearching communities{f' for: {query}' if query else ''}...")

        communities = client.get_communities(query)

        for c in communities.get('data', [])[:20]:
            print(f"  {c.get('name')}: {c.get('subscriber_count', 'N/A')} subscribers")

    else:
        print(f"[ERROR] Unknown command: {command}")


if __name__ == '__main__':
    main()
