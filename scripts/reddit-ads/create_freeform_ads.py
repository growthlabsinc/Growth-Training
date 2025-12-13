#!/usr/bin/env python3
"""
Create new FREE-FORM ads via Reddit Ads API.

Based on Reddit Ads API v3 documentation.
"""

import json
from pathlib import Path
from reddit_ads_api import RedditAdsAuth, RedditAdsClient

# Account info
AD_ACCOUNT_ID = "a2_i36w6tavcafy"
AD_GROUP_ID = "2381056975948045977"

# FREE-FORM ads to create
FREEFORM_ADS = [
    {
        'name': 'Ad 07 - Personal Story FREE-FORM',
        'headline': 'Growth Training - The Accountability App I Built After 2 Years in r/GettingBigger',
        'body': '''**TL;DR:** Built Growth Training after 2 years in the PE community. Lock Screen timer you can't ignore. Progress tracking with charts. **Your data stays 100% private.** Free trial available.

---

## KEY FEATURES

### 🔒 Lock Screen Timer
Your routine stays on your Lock Screen even when your phone is locked. Can't "forget" to train.

### 📊 Progress Charts
Track the metrics that matter and see proof it's working.

### 📏 Measurement Logging
Consistent tracking for BPEL, NBPEL, BPFSL, MSEG, BEG.

### 📋 6 Proven Routines
Beginner to advanced, based on community-proven methods.

---

## PRIVACY

🔐 No account required. Anonymous by default. Face ID lock available.

💚 Annual: $49.99/year (7-day free trial) - Less than $1/week

---

*Happy to answer questions in comments.*''',
        'call_to_action': 'LEARN_MORE',
        'allow_comments': True
    },
    {
        'name': 'Ad 08 - Results FREE-FORM',
        'headline': '6 Months of PE Progress: What Actually Worked (Data Inside)',
        'body': '''**TL;DR:** 0.5" gain in 6 months. The "secret"? Never missing sessions. I tracked everything and built an app to keep myself accountable.

---

## THE DATA

**Month 1:** 28/30 sessions, no measurable gains
**Month 2:** 29/30 sessions, +0.1"
**Month 3:** 30/30 sessions, +0.2" total
**Month 4-6:** 95%+ consistency, **+0.5" total**

---

## THE TURNING POINT

I built a timer that shows on my Lock Screen and won't go away until I finish my session.

---

## THE APP

**Growth Training** - the accountability system that finally worked:

🔒 Lock Screen Timer - can't dismiss
📏 Measurement Logging - BPEL, NBPEL, MSEG tracking
📈 Progress Charts - visualize your gains
🔐 100% Private - no account required

---

**Free trial available.** Less than $1/week after.

*Happy to discuss in comments.*''',
        'call_to_action': 'LEARN_MORE',
        'allow_comments': True
    },
    {
        'name': 'Ad 09 - Science FREE-FORM',
        'headline': "A Redditor's Guide to PE Measurement & Tracking",
        'body': '''**TL;DR:** r/TheScienceOfPE taught me that measurement consistency is everything. Most guys fail PE not because methods don't work, but because they can't track accurately. Built an app to fix this.

---

## THE PROBLEM

❌ Spreadsheets (too much friction)
❌ Notes app (unstructured)
❌ Memory (unreliable)

---

## THE SOLUTION

**Growth Training** - the PE tracking system r/TheScienceOfPE deserves.

### 📏 Measurement Logging
Track BPEL, NBPEL, BPFSL, MSEG, BEG consistently.

### 📊 Progress Visualization
Charts showing trends over time.

### 🔒 Lock Screen Timer
Timer persists on Lock Screen - you WILL remember your session.

### 📚 Research-Based Routines
Methods library based on community-proven techniques.

---

## PRIVACY

🔐 No account required. Anonymous by default. Local storage. Face ID available.

**Free trial available** - less than $1/week after.

---

*Happy to discuss methodology in comments.*''',
        'call_to_action': 'LEARN_MORE',
        'allow_comments': True
    }
]


def main():
    # Load auth
    auth = RedditAdsAuth()
    if not auth.is_token_valid() and not auth.refresh_token:
        print("[ERROR] No valid authentication. Run 'python reddit_ads_api.py auth' first.")
        return

    client = RedditAdsClient(auth)

    print("\n" + "="*60)
    print("CREATING NEW FREE-FORM ADS")
    print("="*60)
    print(f"\nAd Account: {AD_ACCOUNT_ID}")
    print(f"Ad Group: {AD_GROUP_ID}\n")

    for ad in FREEFORM_ADS:
        print(f"\nCreating: {ad['name']}")

        # Build ad data for FREE-FORM
        # Note: FREE-FORM ads don't have click_url - they drive to the Reddit post
        ad_data = {
            'name': ad['name'],
            'ad_group_id': AD_GROUP_ID,
            'configured_status': 'PAUSED',
            'post_type': 'FREE_FORM',  # Try this
            'headline': ad['headline'],
            'body': ad['body'],
            'call_to_action': ad['call_to_action'],
            'allow_comments': ad['allow_comments'],
        }

        print(f"  Payload: {json.dumps(ad_data, indent=2)[:500]}...")

        try:
            result = client.create_ad(AD_ACCOUNT_ID, ad_data)
            print(f"  ✓ Created! ID: {result.get('data', {}).get('id')}")
            print(f"    Status: {result.get('data', {}).get('effective_status')}")
        except Exception as e:
            print(f"  ✗ Error: {e}")

            # Try alternative field names
            print("  Trying alternative format...")
            ad_data_alt = {
                'name': ad['name'],
                'ad_group_id': AD_GROUP_ID,
                'configured_status': 'PAUSED',
                'type': 'FREE_FORM',
                'headline': ad['headline'],
                'body': ad['body'],
            }
            try:
                result = client.create_ad(AD_ACCOUNT_ID, ad_data_alt)
                print(f"  ✓ Created with alt format! ID: {result.get('data', {}).get('id')}")
            except Exception as e2:
                print(f"  ✗ Alt format also failed: {e2}")

    print("\n" + "="*60)
    print("DONE")
    print("="*60)


if __name__ == '__main__':
    main()
