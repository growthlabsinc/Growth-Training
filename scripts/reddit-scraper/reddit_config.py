"""
Reddit API Configuration for PE Content Extraction
"""
import os
from typing import Dict, List
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
env_path = Path(__file__).parent / '.env'
load_dotenv(env_path)

# Reddit API Configuration
REDDIT_CONFIG: Dict[str, str] = {
    'client_id': os.getenv('REDDIT_CLIENT_ID', ''),
    'client_secret': os.getenv('REDDIT_CLIENT_SECRET', ''),
    'user_agent': os.getenv('REDDIT_USER_AGENT', 'GrowthLabs_PE_Scraper/1.0'),
}

# For read-only access to public content, we don't need username/password
# Using Application-Only OAuth (script app in read-only mode)

# Target subreddits for PE content extraction
TARGET_SUBREDDITS: List[str] = os.getenv('TARGET_SUBREDDITS', 'gettingbigger,ajelqforyou').split(',')

# Additional PE-related subreddits for comprehensive content
ADDITIONAL_SUBREDDITS: List[str] = [
    'PEGym',
    'AJelqForYou',
]

# API Rate Limits (Reddit allows 60 requests per minute)
RATE_LIMIT: Dict[str, float] = {
    'requests_per_minute': 60,
    'delay_between_requests': 2.0,  # seconds (conservative to avoid rate limiting)
}

# Content Extraction Settings
EXTRACTION_CONFIG: Dict = {
    'wiki_pages_to_extract': [
        'index',
        'beginner',
        'exercises',
        'routines',
        'safety',
        'glossary',
        'faq',
        'progression',
    ],
    'max_posts_per_sub': 100,  # Top posts to analyze
    'min_upvotes': 10,  # Minimum upvotes for guide consideration
    'min_content_length': 100,  # Minimum words for valid exercise description
}

# PE Exercise Categories
PE_CATEGORIES: List[str] = [
    'Length',
    'Girth',
    'EQ',  # Erection Quality
    'Stamina',
    'Conditioning',
    'Stretching',
    'Jelqing',
    'Pumping',
    'Hanging',
    'Clamping',
    'Kegels',
]

# Difficulty Levels
DIFFICULTY_LEVELS: List[str] = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert'
]

# Output Configuration
OUTPUT_CONFIG: Dict = {
    'output_dir': Path(__file__).parent / 'extracted_data',
    'pe_database_file': 'pe_methods_database.json',
    'extraction_log': 'extraction_log.txt',
    'backup_dir': Path(__file__).parent / 'extracted_data' / 'backups',
}