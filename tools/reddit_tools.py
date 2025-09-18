import requests
import random
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime


class RedditPost(BaseModel):
    """Model for a Reddit post"""
    id: str
    title: str
    author: str
    subreddit: str
    score: int
    num_comments: int
    created_utc: float
    url: str
    permalink: str
    selftext: Optional[str] = None
    thumbnail: Optional[str] = None
    is_video: bool = False
    is_self: bool = False
    
    @property
    def created_datetime(self) -> datetime:
        """Convert UTC timestamp to datetime"""
        return datetime.fromtimestamp(self.created_utc)


class RedditPosts(BaseModel):
    """Collection of Reddit posts"""
    posts: List[RedditPost]
    after: Optional[str] = None
    before: Optional[str] = None
    count: int = 0


class Subreddit(BaseModel):
    """Model for a Subreddit"""
    name: str
    display_name: str
    title: str
    public_description: str
    subscribers: int
    active_user_count: Optional[int] = None
    created_utc: float
    over18: bool
    url: str
    icon_img: Optional[str] = None
    banner_img: Optional[str] = None
    
    @property
    def created_datetime(self) -> datetime:
        """Convert UTC timestamp to datetime"""
        return datetime.fromtimestamp(self.created_utc)


class Subreddits(BaseModel):
    """Collection of Subreddits"""
    subreddits: List[Subreddit]
    after: Optional[str] = None
    before: Optional[str] = None


class RedditComment(BaseModel):
    """Model for a Reddit comment"""
    id: str
    author: str
    body: str
    score: int
    created_utc: float
    edited: bool = False
    parent_id: Optional[str] = None
    replies: List['RedditComment'] = []
    
    @property
    def created_datetime(self) -> datetime:
        """Convert UTC timestamp to datetime"""
        return datetime.fromtimestamp(self.created_utc)


class RedditPostWithComments(BaseModel):
    """Model for a Reddit post with its comments"""
    post: RedditPost
    comments: List[RedditComment]
    comment_count: int


class RedditTools:
    """Reddit API tools for fetching posts and subreddit information"""
    
    def __init__(self):
        self.base_url = "https://www.reddit.com"
        self.user_agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15"
        ]
    
    def get_user_agent(self) -> str:
        """Rotate user agents for requests"""
        return random.choice(self.user_agents)
    
    def _make_request(self, url: str, params: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Make a request to Reddit API"""
        headers = {
            "User-Agent": self.get_user_agent()
        }
        
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        return response.json()
    
    def _parse_post(self, post_data: Dict[str, Any]) -> RedditPost:
        """Parse raw post data into RedditPost model"""
        data = post_data.get("data", {})
        return RedditPost(
            id=data.get("id", ""),
            title=data.get("title", ""),
            author=data.get("author", "[deleted]"),
            subreddit=data.get("subreddit", ""),
            score=data.get("score", 0),
            num_comments=data.get("num_comments", 0),
            created_utc=data.get("created_utc", 0),
            url=data.get("url", ""),
            permalink=f"https://reddit.com{data.get('permalink', '')}",
            selftext=data.get("selftext") if data.get("selftext") else None,
            thumbnail=data.get("thumbnail") if data.get("thumbnail") not in ["self", "default", "nsfw"] else None,
            is_video=data.get("is_video", False),
            is_self=data.get("is_self", False)
        )
    
    def _parse_subreddit(self, sub_data: Dict[str, Any]) -> Subreddit:
        """Parse raw subreddit data into Subreddit model"""
        data = sub_data.get("data", {})
        return Subreddit(
            name=data.get("name", ""),
            display_name=data.get("display_name", ""),
            title=data.get("title", ""),
            public_description=data.get("public_description", ""),
            subscribers=data.get("subscribers", 0),
            active_user_count=data.get("active_user_count"),
            created_utc=data.get("created_utc", 0),
            over18=data.get("over18", False),
            url=f"https://reddit.com{data.get('url', '')}",
            icon_img=data.get("icon_img") if data.get("icon_img") else None,
            banner_img=data.get("banner_background_image") if data.get("banner_background_image") else None
        )
    
    def get_reddit_post(self, subreddit: str, sort: str = "hot", limit: int = 25, 
                       time: str = "day", after: Optional[str] = None) -> RedditPosts:
        """
        Get posts from a subreddit
        
        Args:
            subreddit: Name of the subreddit
            sort: Sort method (hot, new, top, rising)
            limit: Number of posts to retrieve (max 100)
            time: Time period for top posts (hour, day, week, month, year, all)
            after: Pagination token
        
        Returns:
            RedditPosts object containing the posts
        """
        url = f"{self.base_url}/r/{subreddit}/{sort}.json"
        params = {
            "limit": min(limit, 100),
            "raw_json": 1
        }
        
        if sort == "top" and time:
            params["t"] = time
        
        if after:
            params["after"] = after
        
        data = self._make_request(url, params)
        posts = [self._parse_post(child) for child in data.get("data", {}).get("children", [])]
        
        return RedditPosts(
            posts=posts,
            after=data.get("data", {}).get("after"),
            before=data.get("data", {}).get("before"),
            count=len(posts)
        )
    
    def search_post(self, query: str, subreddit: Optional[str] = None, 
                   sort: str = "relevance", limit: int = 25, 
                   time: str = "all") -> RedditPosts:
        """
        Search for posts
        
        Args:
            query: Search query
            subreddit: Limit search to specific subreddit
            sort: Sort method (relevance, hot, top, new, comments)
            limit: Number of posts to retrieve
            time: Time period (hour, day, week, month, year, all)
        
        Returns:
            RedditPosts object containing search results
        """
        if subreddit:
            url = f"{self.base_url}/r/{subreddit}/search.json"
        else:
            url = f"{self.base_url}/search.json"
        
        params = {
            "q": query,
            "sort": sort,
            "limit": min(limit, 100),
            "t": time,
            "raw_json": 1
        }
        
        if subreddit:
            params["restrict_sr"] = "true"
        
        data = self._make_request(url, params)
        posts = [self._parse_post(child) for child in data.get("data", {}).get("children", [])]
        
        return RedditPosts(
            posts=posts,
            after=data.get("data", {}).get("after"),
            before=data.get("data", {}).get("before"),
            count=len(posts)
        )
    
    def search_subreddits(self, query: str, limit: int = 25) -> Subreddits:
        """
        Search for subreddits
        
        Args:
            query: Search query
            limit: Number of subreddits to retrieve
        
        Returns:
            Subreddits object containing search results
        """
        url = f"{self.base_url}/subreddits/search.json"
        params = {
            "q": query,
            "limit": min(limit, 100),
            "raw_json": 1
        }
        
        data = self._make_request(url, params)
        subreddits = [self._parse_subreddit(child) for child in data.get("data", {}).get("children", [])]
        
        return Subreddits(
            subreddits=subreddits,
            after=data.get("data", {}).get("after"),
            before=data.get("data", {}).get("before")
        )
    
    def get_subreddit_about(self, subreddit: str) -> Subreddit:
        """
        Get information about a specific subreddit
        
        Args:
            subreddit: Name of the subreddit
        
        Returns:
            Subreddit object with metadata
        """
        url = f"{self.base_url}/r/{subreddit}/about.json"
        data = self._make_request(url)
        return self._parse_subreddit(data)
    
    def get_popular_post(self, limit: int = 25, geo_filter: Optional[str] = None) -> RedditPosts:
        """
        Get popular posts from all of Reddit
        
        Args:
            limit: Number of posts to retrieve
            geo_filter: Geographic filter (e.g., 'US', 'GB')
        
        Returns:
            RedditPosts object containing popular posts
        """
        url = f"{self.base_url}/r/popular.json"
        params = {
            "limit": min(limit, 100),
            "raw_json": 1
        }
        
        if geo_filter:
            params["geo_filter"] = geo_filter
        
        data = self._make_request(url, params)
        posts = [self._parse_post(child) for child in data.get("data", {}).get("children", [])]
        
        return RedditPosts(
            posts=posts,
            after=data.get("data", {}).get("after"),
            before=data.get("data", {}).get("before"),
            count=len(posts)
        )
    
    def get_all_post(self, sort: str = "hot", limit: int = 25, 
                    time: str = "day", after: Optional[str] = None) -> RedditPosts:
        """
        Get posts from r/all
        
        Args:
            sort: Sort method (hot, new, top, rising)
            limit: Number of posts to retrieve
            time: Time period for top posts (hour, day, week, month, year, all)
            after: Pagination token
        
        Returns:
            RedditPosts object containing posts from r/all
        """
        url = f"{self.base_url}/r/all/{sort}.json"
        params = {
            "limit": min(limit, 100),
            "raw_json": 1
        }
        
        if sort == "top" and time:
            params["t"] = time
        
        if after:
            params["after"] = after
        
        data = self._make_request(url, params)
        posts = [self._parse_post(child) for child in data.get("data", {}).get("children", [])]
        
        return RedditPosts(
            posts=posts,
            after=data.get("data", {}).get("after"),
            before=data.get("data", {}).get("before"),
            count=len(posts)
        )
    
    def get_post_by_id(self, subreddit: str, post_id: str) -> RedditPost:
        """
        Get a specific post by its ID
        
        Args:
            subreddit: Name of the subreddit
            post_id: The post ID
        
        Returns:
            RedditPost object containing the post data
        """
        url = f"{self.base_url}/r/{subreddit}/comments/{post_id}.json"
        params = {
            "raw_json": 1
        }
        
        data = self._make_request(url, params)
        # The response contains the post in the first item of the array
        if data and len(data) > 0:
            post_data = data[0].get("data", {}).get("children", [])[0]
            return self._parse_post(post_data)
        else:
            raise ValueError(f"Post not found: {post_id}")
    
    def _parse_comment(self, comment_data: Dict[str, Any], depth: int = 0, max_depth: int = 3) -> Optional[RedditComment]:
        """Parse raw comment data into RedditComment model"""
        if comment_data.get("kind") != "t1":
            return None
            
        data = comment_data.get("data", {})
        
        # Skip deleted/removed comments
        if data.get("author") in ["[deleted]", "[removed]"] and not data.get("body"):
            return None
            
        comment = RedditComment(
            id=data.get("id", ""),
            author=data.get("author", "[deleted]"),
            body=data.get("body", "[removed]"),
            score=data.get("score", 0),
            created_utc=data.get("created_utc", 0),
            edited=bool(data.get("edited", False)),
            parent_id=data.get("parent_id")
        )
        
        # Parse replies if we haven't reached max depth
        if depth < max_depth and data.get("replies"):
            replies_data = data.get("replies", {})
            if isinstance(replies_data, dict) and replies_data.get("data", {}).get("children"):
                for reply_data in replies_data["data"]["children"]:
                    parsed_reply = self._parse_comment(reply_data, depth + 1, max_depth)
                    if parsed_reply:
                        comment.replies.append(parsed_reply)
        
        return comment
    
    def get_post_with_comments(self, subreddit: str, post_id: str, 
                              sort: str = "best", limit: int = 10) -> RedditPostWithComments:
        """
        Get a specific post with its comments
        
        Args:
            subreddit: Name of the subreddit
            post_id: The post ID
            sort: Comment sort method (best, top, new, controversial, old, qa)
            limit: Maximum number of top-level comments to retrieve
        
        Returns:
            RedditPostWithComments object containing the post and its comments
        """
        url = f"{self.base_url}/r/{subreddit}/comments/{post_id}.json"
        params = {
            "raw_json": 1,
            "sort": sort,
            "limit": limit
        }
        
        data = self._make_request(url, params)
        
        if not data or len(data) < 2:
            raise ValueError(f"Invalid response for post: {post_id}")
        
        # Parse the post
        post_data = data[0].get("data", {}).get("children", [])[0]
        post = self._parse_post(post_data)
        
        # Parse the comments
        comments = []
        comments_data = data[1].get("data", {}).get("children", [])
        
        for comment_data in comments_data:
            parsed_comment = self._parse_comment(comment_data)
            if parsed_comment:
                comments.append(parsed_comment)
        
        return RedditPostWithComments(
            post=post,
            comments=comments,
            comment_count=len(comments)
        )