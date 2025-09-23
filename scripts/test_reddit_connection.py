#!/usr/bin/env python3
"""
Test Reddit API Connection
"""

import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from reddit_config import REDDIT_CONFIG, TARGET_SUBREDDITS
import praw

def test_connection():
    """Test Reddit API connection"""
    print("Testing Reddit API Connection...")
    print("="*50)

    try:
        # Initialize Reddit client
        reddit = praw.Reddit(
            client_id=REDDIT_CONFIG['client_id'],
            client_secret=REDDIT_CONFIG['client_secret'],
            user_agent=REDDIT_CONFIG['user_agent']
        )

        print(f"✅ Client initialized")
        print(f"   Client ID: {REDDIT_CONFIG['client_id'][:10]}...")
        print(f"   User Agent: {REDDIT_CONFIG['user_agent']}")

        # Test basic access
        for submission in reddit.subreddit('test').hot(limit=1):
            print(f"✅ Successfully accessed Reddit API")
            print(f"   Test post: {submission.title[:50]}")
            break

        print("\nTesting target subreddits:")
        print("-"*30)

        for subreddit_name in TARGET_SUBREDDITS:
            try:
                subreddit = reddit.subreddit(subreddit_name)
                print(f"\n📌 r/{subreddit_name}")
                print(f"   Display name: {subreddit.display_name}")
                print(f"   Subscribers: {subreddit.subscribers:,}")
                print(f"   Description: {subreddit.public_description[:100]}...")

                # Check wiki availability
                try:
                    wiki_page = subreddit.wiki['index']
                    print(f"   ✅ Wiki accessible")
                except:
                    print(f"   ⚠️  Wiki not accessible or doesn't exist")

            except Exception as e:
                print(f"   ❌ Error accessing r/{subreddit_name}: {e}")

        print("\n" + "="*50)
        print("✅ Connection test SUCCESSFUL!")
        print("Ready to extract PE content.")
        return True

    except Exception as e:
        print(f"\n❌ Connection test FAILED!")
        print(f"Error: {e}")
        print("\nTroubleshooting:")
        print("1. Check your client_id and client_secret in .env")
        print("2. Ensure your Reddit app is active")
        print("3. Check your internet connection")
        return False

if __name__ == "__main__":
    success = test_connection()
    sys.exit(0 if success else 1)