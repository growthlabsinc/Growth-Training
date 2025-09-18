#!/usr/bin/env python3
"""
Reddit MCP Server - A simple MCP server for Reddit API access
"""

import sys
import json
import logging
from typing import Any, Dict, List, Optional
from tools.reddit_tools import RedditTools

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Initialize Reddit tools
reddit_tools = RedditTools()

class RedditMCPServer:
    def __init__(self):
        self.reddit_tools = RedditTools()
    
    def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle incoming MCP requests"""
        method = request.get("method", "")
        params = request.get("params", {})
        request_id = request.get("id")
        
        logger.info(f"Handling request: {method}")
        
        if method == "initialize":
            return self._handle_initialize(request_id)
        elif method == "tools/list":
            return self._handle_tools_list(request_id)
        elif method == "tools/call":
            return self._handle_tool_call(params, request_id)
        else:
            return self._error_response(request_id, -32601, f"Method not found: {method}")
    
    def _handle_initialize(self, request_id: Any) -> Dict[str, Any]:
        """Handle initialization request"""
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {
                "protocolVersion": "0.1.0",
                "capabilities": {
                    "tools": {}
                },
                "serverInfo": {
                    "name": "reddit-mcp-server",
                    "version": "1.0.0"
                }
            }
        }
    
    def _handle_tools_list(self, request_id: Any) -> Dict[str, Any]:
        """Return list of available tools"""
        tools = [
            {
                "name": "get_reddit_posts",
                "description": "Get posts from a specific subreddit",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "subreddit": {"type": "string", "description": "Name of the subreddit"},
                        "sort": {"type": "string", "enum": ["hot", "new", "top", "rising"], "default": "hot"},
                        "limit": {"type": "integer", "minimum": 1, "maximum": 100, "default": 25},
                        "time": {"type": "string", "enum": ["hour", "day", "week", "month", "year", "all"], "default": "day"},
                        "after": {"type": "string", "description": "Pagination token"}
                    },
                    "required": ["subreddit"]
                }
            },
            {
                "name": "search_reddit_posts",
                "description": "Search for posts across Reddit",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {"type": "string", "description": "Search query"},
                        "subreddit": {"type": "string", "description": "Limit to specific subreddit"},
                        "sort": {"type": "string", "enum": ["relevance", "hot", "top", "new", "comments"], "default": "relevance"},
                        "limit": {"type": "integer", "minimum": 1, "maximum": 100, "default": 25},
                        "time": {"type": "string", "enum": ["hour", "day", "week", "month", "year", "all"], "default": "all"}
                    },
                    "required": ["query"]
                }
            },
            {
                "name": "search_subreddits",
                "description": "Search for subreddits by name or description",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "query": {"type": "string", "description": "Search query"},
                        "limit": {"type": "integer", "minimum": 1, "maximum": 100, "default": 25}
                    },
                    "required": ["query"]
                }
            },
            {
                "name": "get_subreddit_info",
                "description": "Get detailed information about a subreddit",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "subreddit": {"type": "string", "description": "Name of the subreddit"}
                    },
                    "required": ["subreddit"]
                }
            },
            {
                "name": "get_post_with_comments",
                "description": "Get a specific Reddit post with its comments",
                "inputSchema": {
                    "type": "object",
                    "properties": {
                        "subreddit": {"type": "string", "description": "Name of the subreddit"},
                        "post_id": {"type": "string", "description": "ID of the post"},
                        "sort": {"type": "string", "enum": ["best", "top", "new", "controversial", "old", "qa"], "default": "best"},
                        "limit": {"type": "integer", "minimum": 1, "maximum": 50, "default": 10}
                    },
                    "required": ["subreddit", "post_id"]
                }
            }
        ]
        
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {
                "tools": tools
            }
        }
    
    def _handle_tool_call(self, params: Dict[str, Any], request_id: Any) -> Dict[str, Any]:
        """Handle tool execution"""
        tool_name = params.get("name")
        arguments = params.get("arguments", {})
        
        try:
            if tool_name == "get_reddit_posts":
                result = self.reddit_tools.get_reddit_post(
                    subreddit=arguments["subreddit"],
                    sort=arguments.get("sort", "hot"),
                    limit=arguments.get("limit", 25),
                    time=arguments.get("time", "day"),
                    after=arguments.get("after")
                )
            elif tool_name == "search_reddit_posts":
                result = self.reddit_tools.search_post(
                    query=arguments["query"],
                    subreddit=arguments.get("subreddit"),
                    sort=arguments.get("sort", "relevance"),
                    limit=arguments.get("limit", 25),
                    time=arguments.get("time", "all")
                )
            elif tool_name == "search_subreddits":
                result = self.reddit_tools.search_subreddits(
                    query=arguments["query"],
                    limit=arguments.get("limit", 25)
                )
            elif tool_name == "get_subreddit_info":
                result = self.reddit_tools.get_subreddit_about(
                    subreddit=arguments["subreddit"]
                )
            elif tool_name == "get_post_with_comments":
                result = self.reddit_tools.get_post_with_comments(
                    subreddit=arguments["subreddit"],
                    post_id=arguments["post_id"],
                    sort=arguments.get("sort", "best"),
                    limit=arguments.get("limit", 10)
                )
            else:
                return self._error_response(request_id, -32602, f"Unknown tool: {tool_name}")
            
            # Convert result to dict if it has model_dump method
            if hasattr(result, 'model_dump'):
                result_data = result.model_dump()
            else:
                result_data = result
            
            return {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {
                    "content": [
                        {
                            "type": "text",
                            "text": json.dumps(result_data, indent=2)
                        }
                    ]
                }
            }
            
        except Exception as e:
            logger.error(f"Error executing tool {tool_name}: {str(e)}")
            return self._error_response(request_id, -32603, str(e))
    
    def _error_response(self, request_id: Any, code: int, message: str) -> Dict[str, Any]:
        """Create error response"""
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "error": {
                "code": code,
                "message": message
            }
        }
    
    def run(self):
        """Run the MCP server"""
        logger.info("Reddit MCP Server starting...")
        
        # Read from stdin and write to stdout
        while True:
            try:
                line = sys.stdin.readline()
                if not line:
                    break
                
                request = json.loads(line.strip())
                response = self.handle_request(request)
                
                print(json.dumps(response))
                sys.stdout.flush()
                
            except json.JSONDecodeError as e:
                logger.error(f"Invalid JSON: {e}")
                error_response = self._error_response(None, -32700, "Parse error")
                print(json.dumps(error_response))
                sys.stdout.flush()
            except KeyboardInterrupt:
                logger.info("Server shutting down...")
                break
            except Exception as e:
                logger.error(f"Unexpected error: {e}")
                error_response = self._error_response(None, -32603, str(e))
                print(json.dumps(error_response))
                sys.stdout.flush()

if __name__ == "__main__":
    server = RedditMCPServer()
    server.run()