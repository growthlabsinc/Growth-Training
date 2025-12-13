#!/usr/bin/env python3
"""
Fix BROKEN_URL rejection by updating ads with correct App Store URL.

The correct URL is: https://apps.apple.com/us/app/growth-training/id6752875980
"""

import json
from pathlib import Path
from reddit_ads_api import RedditAdsAuth, RedditAdsClient

# Correct App Store URL
CORRECT_APP_STORE_URL = "https://apps.apple.com/us/app/growth-training/id6752875980"

# All ad IDs to update
ALL_ADS = {
    'Ad 01 - Personal Story': '2383329368280784700',
    'Ad 02 - Results Angle TEXT': '2383350838426647972',
    'Ad 03 - Science-Based TEXT': '2383352436311904844',
    'Ad 04 - Personal Story Megathread': '2383353186432429478',
    'Ad 05 - Results Megathread': '2383362549641389821',
    'Ad 06 - Science Megathread': '2383363138007377079',
}


def main():
    # Load auth
    auth = RedditAdsAuth()
    if not auth.is_token_valid() and not auth.refresh_token:
        print("[ERROR] No valid authentication. Run 'python reddit_ads_api.py auth' first.")
        return

    client = RedditAdsClient(auth)

    print("\n" + "="*60)
    print("FIXING BROKEN URLs IN ADS")
    print("="*60)
    print(f"\nNew URL: {CORRECT_APP_STORE_URL}\n")

    for ad_name, ad_id in ALL_ADS.items():
        print(f"\nUpdating: {ad_name} (ID: {ad_id})")

        update_data = {
            'click_url': CORRECT_APP_STORE_URL,
        }

        try:
            result = client.update_ad(ad_id, update_data)
            status = result.get('data', {}).get('effective_status', 'Unknown')
            rejection = result.get('data', {}).get('rejection_reason', 'None')
            print(f"  ✓ Updated click_url")
            print(f"    Status: {status}")
            print(f"    Rejection: {rejection}")
        except Exception as e:
            print(f"  ✗ Error: {e}")

    print("\n" + "="*60)
    print("DONE - All ads updated with correct URL")
    print("="*60)
    print("\nNote: Ads may still show as REJECTED until Reddit re-reviews them.")
    print("You may need to manually re-submit them for review in the UI.")


if __name__ == '__main__':
    main()
