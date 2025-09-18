#!/usr/bin/env python3
"""Test Reddit tools functionality"""

from tools.reddit_tools import RedditTools

# Initialize Reddit tools
reddit_tools = RedditTools()

# Test getting posts from a subreddit
print("Getting posts from r/programming...")
posts = reddit_tools.get_reddit_post(subreddit="programming", limit=5)

# Print the first few posts
for i, post in enumerate(posts.posts[:3]):
    print(f"\n{i+1}. {post.title}")
    print(f"   Score: {post.score} | Comments: {post.num_comments}")
    print(f"   URL: {post.url}")

# Test searching for posts
print("\n\nSearching for 'python tutorial' posts...")
search_results = reddit_tools.search_post(query="python tutorial", limit=3)

for i, post in enumerate(search_results.posts[:3]):
    print(f"\n{i+1}. {post.title}")
    print(f"   Subreddit: r/{post.subreddit}")
    print(f"   Score: {post.score}")