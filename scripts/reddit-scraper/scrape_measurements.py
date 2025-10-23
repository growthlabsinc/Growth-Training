#!/usr/bin/env python3
"""
Scrape PE measurement terminology from Reddit communities
Identifies the most common measurement types used by the community
"""

import json
import time
import re
import logging
from datetime import datetime
from typing import Dict, List, Set
from pathlib import Path
from collections import Counter

import praw
from prawcore.exceptions import ResponseException, RequestException

from reddit_config import (
    REDDIT_CONFIG, TARGET_SUBREDDITS, RATE_LIMIT, OUTPUT_CONFIG
)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(OUTPUT_CONFIG['output_dir'] / 'measurement_extraction.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Common PE measurement acronyms and patterns
MEASUREMENT_PATTERNS = {
    # Length measurements
    r'\bBPEL\b': 'Bone Pressed Erect Length',
    r'\bNBPEL\b': 'Non-Bone Pressed Erect Length',
    r'\bBPFSL\b': 'Bone Pressed Flaccid Stretched Length',
    r'\bNBPFSL\b': 'Non-Bone Pressed Flaccid Stretched Length',
    r'\bFSL\b': 'Flaccid Stretched Length',
    r'\bFL\b': 'Flaccid Length',
    r'\bEL\b': 'Erect Length',
    r'\bBPFL\b': 'Bone Pressed Flaccid Length',

    # Girth measurements
    r'\bMSEG\b': 'Mid-Shaft Erect Girth',
    r'\bBEG\b': 'Base Erect Girth',
    r'\bEG\b': 'Erect Girth',
    r'\bMEG\b': 'Mid Erect Girth',
    r'\bFG\b': 'Flaccid Girth',
    r'\bMSFG\b': 'Mid-Shaft Flaccid Girth',
    r'\bBFG\b': 'Base Flaccid Girth',
    r'\bGlans Girth\b': 'Glans Girth',

    # Other measurements
    r'\bEQ\b': 'Erection Quality',
    r'\bLOT\b': 'Loss of Tugback',
    r'\bVolume\b': 'Volume',
    r'\bCircumference\b': 'Circumference',
}


class MeasurementTerminologyExtractor:
    """Extracts measurement terminology from Reddit PE communities"""

    def __init__(self):
        """Initialize the Reddit client and setup"""
        self.reddit = self._initialize_reddit()
        self.measurement_mentions = Counter()
        self.measurement_context = {}
        self.measurement_formats = []
        self.extraction_stats = {
            'posts_analyzed': 0,
            'comments_analyzed': 0,
            'measurements_found': 0,
            'start_time': datetime.now().isoformat()
        }

        # Create output directory
        OUTPUT_CONFIG['output_dir'].mkdir(exist_ok=True)

    def _initialize_reddit(self) -> praw.Reddit:
        """Initialize Reddit API client"""
        try:
            reddit = praw.Reddit(
                client_id=REDDIT_CONFIG['client_id'],
                client_secret=REDDIT_CONFIG['client_secret'],
                user_agent=REDDIT_CONFIG['user_agent']
            )
            # Test the connection
            for _ in reddit.subreddit('test').hot(limit=1):
                pass
            logger.info("✅ Successfully connected to Reddit API")
            return reddit
        except Exception as e:
            logger.error(f"❌ Failed to initialize Reddit client: {e}")
            raise

    def extract_all_measurements(self) -> Dict:
        """Main extraction method - processes all target subreddits"""
        logger.info(f"Starting measurement extraction from {len(TARGET_SUBREDDITS)} subreddits")

        for subreddit_name in TARGET_SUBREDDITS:
            logger.info(f"\n{'='*50}")
            logger.info(f"Processing r/{subreddit_name}")
            logger.info(f"{'='*50}")

            try:
                subreddit = self.reddit.subreddit(subreddit_name)

                # Extract from top posts
                self._extract_from_posts(subreddit, 'top', limit=200)

                # Extract from hot posts
                self._extract_from_posts(subreddit, 'hot', limit=100)

                # Search for measurement-related posts
                self._search_measurement_posts(subreddit)

                # Rate limiting
                time.sleep(RATE_LIMIT['delay_between_requests'])

            except Exception as e:
                logger.error(f"Error processing r/{subreddit_name}: {e}")
                continue

        # Save results
        self._save_results()

        return self._generate_report()

    def _extract_from_posts(self, subreddit, sort_type: str, limit: int) -> None:
        """Extract measurements from posts"""
        logger.info(f"Extracting from {sort_type} posts...")

        try:
            if sort_type == 'top':
                posts = subreddit.top(time_filter='all', limit=limit)
            elif sort_type == 'hot':
                posts = subreddit.hot(limit=limit)
            else:
                return

            for post in posts:
                # Analyze post title and body
                self._analyze_text(post.title, 'post_title')
                if post.selftext:
                    self._analyze_text(post.selftext, 'post_body')

                self.extraction_stats['posts_analyzed'] += 1

                # Analyze top comments
                try:
                    post.comments.replace_more(limit=0)  # Don't fetch "more comments"
                    for comment in post.comments.list()[:50]:  # Top 50 comments
                        if hasattr(comment, 'body'):
                            self._analyze_text(comment.body, 'comment')
                            self.extraction_stats['comments_analyzed'] += 1
                except Exception as e:
                    logger.debug(f"Error processing comments: {e}")

                # Rate limiting
                if self.extraction_stats['posts_analyzed'] % 10 == 0:
                    time.sleep(1)
                    logger.info(f"  Analyzed {self.extraction_stats['posts_analyzed']} posts...")

        except Exception as e:
            logger.error(f"Error extracting from {sort_type} posts: {e}")

    def _search_measurement_posts(self, subreddit) -> None:
        """Search for posts specifically about measurements"""
        search_terms = [
            'measurement', 'gains', 'progress', 'tracking',
            'BPEL', 'girth', 'length', 'stats'
        ]

        logger.info("Searching for measurement-related posts...")

        for term in search_terms:
            try:
                results = subreddit.search(term, limit=50, time_filter='all')
                for post in results:
                    self._analyze_text(post.title, 'search_title')
                    if post.selftext:
                        self._analyze_text(post.selftext, 'search_body')

                time.sleep(RATE_LIMIT['delay_between_requests'])
            except Exception as e:
                logger.debug(f"Error searching for '{term}': {e}")

    def _analyze_text(self, text: str, source_type: str) -> None:
        """Analyze text for measurement mentions"""
        if not text:
            return

        # Find all measurement mentions
        for pattern, full_name in MEASUREMENT_PATTERNS.items():
            matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in matches:
                matched_text = match.group(0)
                self.measurement_mentions[full_name] += 1
                self.extraction_stats['measurements_found'] += 1

                # Store context (surrounding text)
                start = max(0, match.start() - 50)
                end = min(len(text), match.end() + 50)
                context = text[start:end].replace('\n', ' ').strip()

                if full_name not in self.measurement_context:
                    self.measurement_context[full_name] = []

                # Store up to 5 examples of context
                if len(self.measurement_context[full_name]) < 5:
                    self.measurement_context[full_name].append({
                        'matched': matched_text,
                        'context': context,
                        'source': source_type
                    })

        # Extract measurement formats (e.g., "6.5 x 5.0" or "7" BPEL x 5.5" MSEG")
        format_patterns = [
            r'(\d+\.?\d*)\s*["\']?\s*x\s*(\d+\.?\d*)\s*["\']?',  # "6.5 x 5.0"
            r'(\d+\.?\d*)\s*(?:inches?|cm|in|″)\s*x\s*(\d+\.?\d*)\s*(?:inches?|cm|in|″)',  # "6.5 inches x 5.0 inches"
            r'L:\s*(\d+\.?\d*)\s*["\']?\s*G:\s*(\d+\.?\d*)\s*["\']?',  # "L: 6.5 G: 5.0"
        ]

        for pattern in format_patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in matches:
                format_example = match.group(0)
                if format_example not in [f['example'] for f in self.measurement_formats]:
                    self.measurement_formats.append({
                        'example': format_example,
                        'pattern': pattern
                    })

    def _generate_report(self) -> Dict:
        """Generate analysis report"""
        # Sort by frequency
        sorted_measurements = self.measurement_mentions.most_common()

        report = {
            'extraction_date': datetime.now().isoformat(),
            'statistics': self.extraction_stats,
            'measurement_types': [
                {
                    'name': name,
                    'count': count,
                    'examples': self.measurement_context.get(name, [])
                }
                for name, count in sorted_measurements
            ],
            'measurement_formats': self.measurement_formats[:20],  # Top 20 formats
            'recommendations': self._generate_recommendations(sorted_measurements)
        }

        return report

    def _generate_recommendations(self, sorted_measurements: List) -> Dict:
        """Generate recommendations for app implementation"""
        # Top 10 most common measurements
        top_measurements = sorted_measurements[:10]

        # Categorize measurements
        length_measurements = []
        girth_measurements = []
        other_measurements = []

        for name, count in top_measurements:
            name_lower = name.lower()
            if 'length' in name_lower:
                length_measurements.append({'name': name, 'count': count})
            elif 'girth' in name_lower or 'circumference' in name_lower:
                girth_measurements.append({'name': name, 'count': count})
            else:
                other_measurements.append({'name': name, 'count': count})

        return {
            'top_10_measurements': [{'name': name, 'count': count} for name, count in top_measurements],
            'length_measurements': length_measurements,
            'girth_measurements': girth_measurements,
            'other_measurements': other_measurements,
            'suggested_primary_measurements': [
                'Bone Pressed Erect Length',
                'Mid-Shaft Erect Girth',
                'Erection Quality'
            ],
            'suggested_secondary_measurements': [
                'Non-Bone Pressed Erect Length',
                'Bone Pressed Flaccid Stretched Length',
                'Base Erect Girth',
                'Flaccid Length'
            ]
        }

    def _save_results(self) -> None:
        """Save extraction results to JSON file"""
        logger.info(f"\n{'='*50}")
        logger.info("Saving results...")
        logger.info(f"{'='*50}")

        report = self._generate_report()

        # Save main file
        output_file = OUTPUT_CONFIG['output_dir'] / 'measurement_terminology.json'
        with open(output_file, 'w') as f:
            json.dump(report, f, indent=2)

        logger.info(f"✅ Saved measurement analysis to {output_file}")

        # Save human-readable report
        self._save_text_report(report)

    def _save_text_report(self, report: Dict) -> None:
        """Save human-readable text report"""
        lines = []
        lines.append("="*60)
        lines.append("PE MEASUREMENT TERMINOLOGY ANALYSIS")
        lines.append("="*60)
        lines.append(f"Analysis Date: {report['extraction_date']}")
        lines.append(f"Posts Analyzed: {report['statistics']['posts_analyzed']}")
        lines.append(f"Comments Analyzed: {report['statistics']['comments_analyzed']}")
        lines.append(f"Total Measurements Found: {report['statistics']['measurements_found']}")
        lines.append("")

        lines.append("TOP 10 MOST COMMON MEASUREMENTS:")
        lines.append("-" * 60)
        for i, item in enumerate(report['recommendations']['top_10_measurements'], 1):
            lines.append(f"{i:2d}. {item['name']:<40} ({item['count']} mentions)")
        lines.append("")

        lines.append("RECOMMENDED PRIMARY MEASUREMENTS FOR APP:")
        lines.append("-" * 60)
        for measurement in report['recommendations']['suggested_primary_measurements']:
            lines.append(f"  • {measurement}")
        lines.append("")

        lines.append("RECOMMENDED SECONDARY MEASUREMENTS FOR APP:")
        lines.append("-" * 60)
        for measurement in report['recommendations']['suggested_secondary_measurements']:
            lines.append(f"  • {measurement}")
        lines.append("")

        lines.append("LENGTH MEASUREMENTS BY FREQUENCY:")
        lines.append("-" * 60)
        for item in report['recommendations']['length_measurements']:
            lines.append(f"  • {item['name']:<40} ({item['count']} mentions)")
        lines.append("")

        lines.append("GIRTH MEASUREMENTS BY FREQUENCY:")
        lines.append("-" * 60)
        for item in report['recommendations']['girth_measurements']:
            lines.append(f"  • {item['name']:<40} ({item['count']} mentions)")
        lines.append("")

        lines.append("COMMON MEASUREMENT FORMATS:")
        lines.append("-" * 60)
        for i, fmt in enumerate(report['measurement_formats'][:10], 1):
            lines.append(f"  {i}. {fmt['example']}")
        lines.append("")

        # Save report
        report_file = OUTPUT_CONFIG['output_dir'] / 'measurement_analysis_report.txt'
        with open(report_file, 'w') as f:
            f.write('\n'.join(lines))

        logger.info(f"✅ Text report saved to {report_file}")

        # Print summary to console
        print("\n" + "\n".join(lines))


def main():
    """Main execution function"""
    print("="*60)
    print("PE MEASUREMENT TERMINOLOGY EXTRACTION")
    print("="*60)

    try:
        extractor = MeasurementTerminologyExtractor()
        results = extractor.extract_all_measurements()

        print(f"\n✅ Extraction completed successfully!")
        print(f"Total measurements found: {results['statistics']['measurements_found']}")
        print(f"Unique measurement types: {len(results['measurement_types'])}")

    except Exception as e:
        print(f"\n❌ Extraction failed: {e}")
        logger.error(f"Fatal error: {e}", exc_info=True)
        return 1

    return 0


if __name__ == "__main__":
    exit(main())
