from fastmcp import FastMCP
from tools.reddit_tools import RedditTools
from typing import Optional

# Initialize the MCP server
mcp = FastMCP("reddit-mcp")

# Initialize Reddit tools
reddit_tools = RedditTools()


@mcp.tool()
def get_reddit_posts(
    subreddit: str,
    sort: str = "hot",
    limit: int = 25,
    time: str = "day",
    after: Optional[str] = None
) -> dict:
    """
    Get posts from a specific subreddit
    
    Args:
        subreddit: Name of the subreddit (e.g., 'python', 'programming')
        sort: Sort method - 'hot', 'new', 'top', or 'rising' (default: 'hot')
        limit: Number of posts to retrieve, max 100 (default: 25)
        time: Time period for top posts - 'hour', 'day', 'week', 'month', 'year', 'all' (default: 'day')
        after: Pagination token for fetching next page
    
    Returns:
        Dictionary containing posts and pagination info
    """
    result = reddit_tools.get_reddit_post(subreddit, sort, limit, time, after)
    return result.model_dump()


@mcp.tool()
def search_reddit_posts(
    query: str,
    subreddit: Optional[str] = None,
    sort: str = "relevance",
    limit: int = 25,
    time: str = "all"
) -> dict:
    """
    Search for posts across Reddit or within a specific subreddit
    
    Args:
        query: Search query string
        subreddit: Limit search to specific subreddit (optional)
        sort: Sort method - 'relevance', 'hot', 'top', 'new', 'comments' (default: 'relevance')
        limit: Number of posts to retrieve, max 100 (default: 25)
        time: Time period - 'hour', 'day', 'week', 'month', 'year', 'all' (default: 'all')
    
    Returns:
        Dictionary containing search results
    """
    result = reddit_tools.search_post(query, subreddit, sort, limit, time)
    return result.model_dump()


@mcp.tool()
def search_subreddits(query: str, limit: int = 25) -> dict:
    """
    Search for subreddits by name or description
    
    Args:
        query: Search query string
        limit: Number of subreddits to retrieve, max 100 (default: 25)
    
    Returns:
        Dictionary containing matching subreddits
    """
    result = reddit_tools.search_subreddits(query, limit)
    return result.model_dump()


@mcp.tool()
def get_subreddit_info(subreddit: str) -> dict:
    """
    Get detailed information about a specific subreddit
    
    Args:
        subreddit: Name of the subreddit
    
    Returns:
        Dictionary containing subreddit metadata including description, subscriber count, etc.
    """
    result = reddit_tools.get_subreddit_about(subreddit)
    return result.model_dump()


@mcp.tool()
def get_popular_posts(limit: int = 25, geo_filter: Optional[str] = None) -> dict:
    """
    Get popular posts from across Reddit
    
    Args:
        limit: Number of posts to retrieve, max 100 (default: 25)
        geo_filter: Geographic filter like 'US', 'GB', etc. (optional)
    
    Returns:
        Dictionary containing popular posts
    """
    result = reddit_tools.get_popular_post(limit, geo_filter)
    return result.model_dump()


@mcp.tool()
def get_all_posts(
    sort: str = "hot",
    limit: int = 25,
    time: str = "day",
    after: Optional[str] = None
) -> dict:
    """
    Get posts from r/all (all of Reddit)
    
    Args:
        sort: Sort method - 'hot', 'new', 'top', or 'rising' (default: 'hot')
        limit: Number of posts to retrieve, max 100 (default: 25)
        time: Time period for top posts - 'hour', 'day', 'week', 'month', 'year', 'all' (default: 'day')
        after: Pagination token for fetching next page
    
    Returns:
        Dictionary containing posts from r/all
    """
    result = reddit_tools.get_all_post(sort, limit, time, after)
    return result.model_dump()


if __name__ == "__main__":
    # Run the MCP server
    mcp.run()