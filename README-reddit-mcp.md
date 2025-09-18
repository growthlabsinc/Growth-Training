# Reddit MCP Server

A Model Context Protocol (MCP) server for interacting with Reddit's public API.

## Features

- Get posts from specific subreddits
- Search posts across Reddit
- Search for subreddits
- Get subreddit information
- Get popular posts
- Get posts from r/all
- User agent rotation for requests
- Pagination support

## Installation

```bash
pip install -r requirements-reddit-mcp.txt
```

## Usage

### Run the server

```bash
python mcpreddit.py
```

### Available Tools

1. **get_reddit_posts** - Get posts from a specific subreddit
2. **search_reddit_posts** - Search for posts
3. **search_subreddits** - Search for subreddits
4. **get_subreddit_info** - Get detailed subreddit information
5. **get_popular_posts** - Get popular posts from Reddit
6. **get_all_posts** - Get posts from r/all

### Example Usage

```python
# Get hot posts from r/python
get_reddit_posts(subreddit="python", sort="hot", limit=10)

# Search for posts about machine learning
search_reddit_posts(query="machine learning", sort="relevance", limit=20)

# Get information about a subreddit
get_subreddit_info(subreddit="programming")

# Get popular posts
get_popular_posts(limit=25, geo_filter="US")
```

## Data Models

- **RedditPost**: Individual post with title, author, score, comments, etc.
- **RedditPosts**: Collection of posts with pagination
- **Subreddit**: Subreddit metadata
- **Subreddits**: Collection of subreddits

## Notes

- The Reddit API has rate limits. Be mindful of request frequency.
- This uses Reddit's public JSON API which doesn't require authentication.
- Maximum limit per request is 100 posts.