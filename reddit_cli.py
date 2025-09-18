#!/usr/bin/env python3
"""
Simple CLI to fetch a specific Reddit post using the Reddit tools
"""

import json
from tools.reddit_tools import RedditTools

def fetch_reddit_post(subreddit: str, post_id: str):
    """Fetch a specific Reddit post and its comments"""
    reddit_tools = RedditTools()
    
    try:
        # Get the post by ID
        post = reddit_tools.get_post_by_id(subreddit, post_id)
        
        # Create a formatted output
        output = {
            "post": {
                "title": post.title,
                "author": post.author,
                "subreddit": post.subreddit,
                "score": post.score,
                "num_comments": post.num_comments,
                "created": post.created_datetime.isoformat(),
                "url": post.url,
                "permalink": post.permalink,
                "content": post.selftext
            }
        }
        
        # Note: The current implementation doesn't fetch comments directly,
        # but we can get the full thread data including comments
        url = f"https://www.reddit.com/r/{subreddit}/comments/{post_id}.json"
        params = {"raw_json": 1}
        headers = {"User-Agent": reddit_tools.get_user_agent()}
        
        import requests
        response = requests.get(url, headers=headers, params=params)
        data = response.json()
        
        # Extract comments if available
        if len(data) > 1:
            comments_data = data[1].get("data", {}).get("children", [])
            comments = []
            
            for comment_data in comments_data[:3]:  # Get top 3 comments
                if comment_data.get("kind") == "t1":  # t1 is comment type
                    comment = comment_data.get("data", {})
                    if comment.get("body"):
                        comments.append({
                            "author": comment.get("author", "[deleted]"),
                            "score": comment.get("score", 0),
                            "body": comment.get("body", ""),
                            "created": comment.get("created_utc", 0)
                        })
            
            output["top_comments"] = comments
        
        return output
        
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    # Fetch the SABRE techniques post
    result = fetch_reddit_post("AngionMethod", "fwqiri")
    print(json.dumps(result, indent=2))