#!/usr/bin/env python3
"""
Update Reddit Ads to FREE-FORM type via API.

Based on Reddit Ads API documentation:
- PATCH https://ads-api.reddit.com/api/v3/ads/{ad_id}
"""

import json
from pathlib import Path
from reddit_ads_api import RedditAdsAuth, RedditAdsClient

# Ad IDs from our uploaded ads
ADS_TO_UPDATE = {
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

    # First, get current ad details to see what fields are available
    print("\n" + "="*60)
    print("FETCHING CURRENT AD DETAILS")
    print("="*60)

    for ad_name, ad_id in ADS_TO_UPDATE.items():
        print(f"\nFetching: {ad_name} (ID: {ad_id})")
        try:
            ad_details = client.get_ad(ad_id)
            print(json.dumps(ad_details, indent=2))
        except Exception as e:
            print(f"Error fetching ad: {e}")

    # Try to update one ad - just change the name first to test
    print("\n" + "="*60)
    print("ATTEMPTING TO UPDATE AD")
    print("="*60)

    test_ad_name = 'Ad 04 - Personal Story Megathread'
    test_ad_id = ADS_TO_UPDATE[test_ad_name]

    # Start with minimal update to test endpoint
    update_data = {
        'name': 'Ad 04 - Personal Story Megathread (FREE-FORM)',
        'configured_status': 'PAUSED',
    }

    print(f"\nUpdating: {test_ad_name}")
    print(f"Ad ID: {test_ad_id}")
    print(f"Update payload:")
    print(json.dumps(update_data, indent=2))

    try:
        result = client.update_ad(test_ad_id, update_data)
        print("\nSuccess! Updated ad:")
        print(json.dumps(result, indent=2))
    except Exception as e:
        print(f"\nError updating ad: {e}")


if __name__ == '__main__':
    main()
