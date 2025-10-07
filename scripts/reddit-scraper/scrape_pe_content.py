#!/usr/bin/env python3
"""
PE Content Scraper for Reddit Communities
Extracts exercises, routines, and guides from PE subreddits
"""

import json
import time
import re
import logging
from datetime import datetime
from typing import Dict, List, Optional, Any
from pathlib import Path
import hashlib

import praw
from praw.models import WikiPage, Submission
from prawcore.exceptions import ResponseException, RequestException
import requests

from reddit_config import (
    REDDIT_CONFIG, TARGET_SUBREDDITS, RATE_LIMIT,
    EXTRACTION_CONFIG, PE_CATEGORIES, DIFFICULTY_LEVELS,
    OUTPUT_CONFIG
)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(OUTPUT_CONFIG['output_dir'] / OUTPUT_CONFIG['extraction_log']),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class PEContentExtractor:
    """Extracts PE content from Reddit communities"""

    def __init__(self):
        """Initialize the Reddit client and setup"""
        self.reddit = self._initialize_reddit()
        self.extracted_methods = {}
        self.extraction_stats = {
            'wikis_processed': 0,
            'posts_processed': 0,
            'methods_extracted': 0,
            'errors': 0,
            'start_time': datetime.now().isoformat()
        }

        # Create output directory
        OUTPUT_CONFIG['output_dir'].mkdir(exist_ok=True)
        OUTPUT_CONFIG['backup_dir'].mkdir(exist_ok=True)

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

    def extract_all_content(self) -> Dict:
        """Main extraction method - processes all target subreddits"""
        logger.info(f"Starting extraction from {len(TARGET_SUBREDDITS)} subreddits")

        for subreddit_name in TARGET_SUBREDDITS:
            logger.info(f"\n{'='*50}")
            logger.info(f"Processing r/{subreddit_name}")
            logger.info(f"{'='*50}")

            try:
                subreddit = self.reddit.subreddit(subreddit_name)

                # Extract wiki content
                self._extract_wiki_content(subreddit)

                # Extract top posts/guides
                self._extract_top_guides(subreddit)

                # Rate limiting
                time.sleep(RATE_LIMIT['delay_between_requests'])

            except Exception as e:
                logger.error(f"Error processing r/{subreddit_name}: {e}")
                self.extraction_stats['errors'] += 1
                continue

        # Process and structure the extracted content
        self._process_extracted_content()

        # Save results
        self._save_results()

        return self.extracted_methods

    def _extract_wiki_content(self, subreddit) -> None:
        """Extract content from subreddit wiki pages"""
        logger.info(f"Extracting wiki pages from r/{subreddit.display_name}")

        try:
            wiki_pages = subreddit.wiki

            for page_name in EXTRACTION_CONFIG['wiki_pages_to_extract']:
                try:
                    logger.info(f"  - Fetching wiki page: {page_name}")
                    page = wiki_pages[page_name]
                    content = page.content_md

                    # Parse exercises from wiki content
                    exercises = self._parse_exercises_from_text(
                        content,
                        source_url=f"https://reddit.com/r/{subreddit.display_name}/wiki/{page_name}",
                        source_type='wiki'
                    )

                    for exercise in exercises:
                        self._add_exercise(exercise)

                    self.extraction_stats['wikis_processed'] += 1
                    time.sleep(RATE_LIMIT['delay_between_requests'])

                except Exception as e:
                    logger.warning(f"  - Could not fetch wiki page {page_name}: {e}")
                    continue

        except Exception as e:
            logger.error(f"Error accessing wiki for r/{subreddit.display_name}: {e}")

    def _extract_top_guides(self, subreddit) -> None:
        """Extract top posts and guides from subreddit"""
        logger.info(f"Extracting top guides from r/{subreddit.display_name}")

        try:
            # Get top posts of all time
            top_posts = subreddit.top(time_filter='all', limit=EXTRACTION_CONFIG['max_posts_per_sub'])

            for post in top_posts:
                # Filter for guides and tutorials
                if self._is_guide_post(post):
                    logger.info(f"  - Processing guide: {post.title[:50]}...")

                    # Parse exercises from post
                    exercises = self._parse_exercises_from_text(
                        post.selftext,
                        source_url=post.url,
                        source_type='guide',
                        title=post.title,
                        upvotes=post.score
                    )

                    for exercise in exercises:
                        self._add_exercise(exercise)

                    self.extraction_stats['posts_processed'] += 1
                    time.sleep(RATE_LIMIT['delay_between_requests'])

        except Exception as e:
            logger.error(f"Error extracting guides from r/{subreddit.display_name}: {e}")

    def _is_guide_post(self, post: Submission) -> bool:
        """Check if a post is likely a guide or tutorial"""
        guide_keywords = [
            'guide', 'tutorial', 'routine', 'method', 'exercise',
            'how to', 'beginner', 'newbie', 'program', 'technique'
        ]

        title_lower = post.title.lower()

        # Check title for keywords
        if any(keyword in title_lower for keyword in guide_keywords):
            # Check if it has substantial content
            if len(post.selftext) > 500 and post.score >= EXTRACTION_CONFIG['min_upvotes']:
                return True

        return False

    def _parse_exercises_from_text(self, text: str, source_url: str,
                                   source_type: str, title: str = None,
                                   upvotes: int = 0) -> List[Dict]:
        """Parse exercise information from text content"""
        exercises = []

        # Common PE exercise patterns
        exercise_patterns = [
            r'(?:^|\n)#+\s*(.+?(?:Jelq|Stretch|Squeeze|Pump|Hang|Clamp|Kegel|Exercise).*?)(?:\n|$)',
            r'(?:^|\n)\*\*(.+?(?:Jelq|Stretch|Squeeze|Pump|Hang|Clamp|Kegel).*?)\*\*',
            r'(?:^|\n)(?:\d+\.|\*)\s*(.+?(?:Jelq|Stretch|Squeeze|Pump|Hang|Clamp|Kegel).*?)(?:\n|$)',
        ]

        # Find potential exercises
        potential_exercises = set()
        for pattern in exercise_patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE | re.MULTILINE)
            for match in matches:
                exercise_name = match.group(1).strip()
                if len(exercise_name) > 3 and len(exercise_name) < 100:
                    potential_exercises.add(exercise_name)

        # Extract details for each potential exercise
        for exercise_name in potential_exercises:
            exercise_data = self._extract_exercise_details(
                exercise_name, text, source_url, source_type, upvotes
            )
            if exercise_data:
                exercises.append(exercise_data)

        return exercises

    def _extract_exercise_details(self, exercise_name: str, full_text: str,
                                 source_url: str, source_type: str,
                                 upvotes: int) -> Optional[Dict]:
        """Extract detailed information about a specific exercise"""

        # Clean exercise name
        exercise_name = re.sub(r'[#\*\-\d\.]', '', exercise_name).strip()

        # Generate unique ID
        exercise_id = self._generate_exercise_id(exercise_name)

        # Find the section about this exercise
        exercise_section = self._extract_section(full_text, exercise_name)

        if not exercise_section or len(exercise_section) < EXTRACTION_CONFIG['min_content_length']:
            return None

        # Extract components
        instructions = self._extract_instructions(exercise_section)
        warnings = self._extract_warnings(exercise_section)
        duration = self._extract_duration(exercise_section)
        category = self._determine_category(exercise_name, exercise_section)
        difficulty = self._determine_difficulty(exercise_section)
        equipment = self._extract_equipment(exercise_section)

        return {
            'id': exercise_id,
            'name': exercise_name,
            'category': category,
            'difficulty': difficulty,
            'description': self._extract_description(exercise_section),
            'instructions': instructions,
            'duration': duration,
            'equipment': equipment,
            'warnings': warnings,
            'prerequisites': self._extract_prerequisites(exercise_section),
            'source_url': source_url,
            'source_type': source_type,
            'community_rating': upvotes,
            'extracted_date': datetime.now().isoformat(),
        }

    def _generate_exercise_id(self, name: str) -> str:
        """Generate a unique ID for an exercise"""
        # Create slug from name
        slug = re.sub(r'[^a-zA-Z0-9]+', '_', name.lower())
        slug = slug.strip('_')

        # Ensure uniqueness
        base_slug = slug
        counter = 1
        while slug in self.extracted_methods:
            slug = f"{base_slug}_{counter}"
            counter += 1

        return slug

    def _extract_section(self, text: str, exercise_name: str) -> str:
        """Extract the section of text related to a specific exercise"""
        # Try to find the exercise section
        patterns = [
            rf'(?:^|\n).*?{re.escape(exercise_name)}.*?\n(.*?)(?:\n#|\n\*\*|\Z)',
            rf'{re.escape(exercise_name)}.*?\n+(.*?)(?:\n\n|\Z)',
        ]

        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE | re.DOTALL)
            if match:
                return match.group(1)[:2000]  # Limit section length

        return ""

    def _extract_instructions(self, text: str) -> str:
        """Extract step-by-step instructions from text"""
        # Look for numbered lists or bullet points
        instruction_patterns = [
            r'(?:Instructions?|Steps?|How to|Technique|Method).*?:(.*?)(?:\n\n|\Z)',
            r'(?:\d+\..*?\n)+',
            r'(?:\*.*?\n)+',
        ]

        for pattern in instruction_patterns:
            match = re.search(pattern, text, re.IGNORECASE | re.DOTALL)
            if match:
                instructions = match.group(1) if match.lastindex else match.group(0)
                # Clean up
                instructions = re.sub(r'\n+', '\n', instructions).strip()
                if len(instructions) > 50:
                    return instructions

        # Fallback: use the first substantial paragraph
        paragraphs = text.split('\n\n')
        for para in paragraphs:
            if len(para) > 100:
                return para.strip()

        return text[:500].strip()

    def _extract_warnings(self, text: str) -> List[str]:
        """Extract safety warnings from text"""
        warnings = []

        warning_patterns = [
            r'(?:Warning|Caution|Important|Safety|Danger|Risk).*?:(.*?)(?:\n|\Z)',
            r'(?:Do not|Don\'t|Never|Avoid).*?(?:\.|!)',
        ]

        for pattern in warning_patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in matches:
                warning = match.group(1) if match.lastindex else match.group(0)
                warning = warning.strip()
                if len(warning) > 10:
                    warnings.append(warning)

        return list(set(warnings))[:5]  # Limit to 5 unique warnings

    def _extract_duration(self, text: str) -> str:
        """Extract duration/repetition information"""
        duration_patterns = [
            r'(\d+[-\s]?\d*\s*(?:minutes?|mins?|seconds?|secs?|reps?|repetitions?|sets?))',
            r'(?:Duration|Time|Length).*?(\d+.*?)(?:\.|,|\n)',
        ]

        for pattern in duration_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                return match.group(1).strip()

        return "As prescribed"

    def _determine_category(self, name: str, text: str) -> str:
        """Determine the category of an exercise"""
        name_lower = name.lower()
        text_lower = text.lower()

        category_keywords = {
            'Jelqing': ['jelq', 'milk'],
            'Stretching': ['stretch', 'pull', 'extend'],
            'Pumping': ['pump', 'vacuum'],
            'Hanging': ['hang', 'weight', 'extender'],
            'Clamping': ['clamp', 'constrict'],
            'Kegels': ['kegel', 'pc muscle', 'pelvic floor'],
            'Girth': ['girth', 'thickness', 'width'],
            'Length': ['length', 'elongat', 'lengthen'],
            'EQ': ['erection', 'eq ', 'hardness', 'quality'],
        }

        for category, keywords in category_keywords.items():
            if any(kw in name_lower or kw in text_lower for kw in keywords):
                return category

        return 'General'

    def _determine_difficulty(self, text: str) -> str:
        """Determine difficulty level from text"""
        text_lower = text.lower()

        if any(word in text_lower for word in ['beginner', 'newbie', 'start', 'basic', 'simple']):
            return 'Beginner'
        elif any(word in text_lower for word in ['advanced', 'expert', 'extreme', 'intense']):
            return 'Advanced'
        elif any(word in text_lower for word in ['intermediate', 'moderate']):
            return 'Intermediate'

        return 'Intermediate'  # Default

    def _extract_equipment(self, text: str) -> List[str]:
        """Extract required equipment from text"""
        equipment = []

        equipment_keywords = [
            'pump', 'cylinder', 'gauge', 'lubricant', 'lube', 'weight',
            'hanger', 'extender', 'clamp', 'wrap', 'rice sock', 'warm water',
            'towel', 'cock ring', 'ring'
        ]

        text_lower = text.lower()
        for item in equipment_keywords:
            if item in text_lower:
                equipment.append(item.title())

        return list(set(equipment))

    def _extract_prerequisites(self, text: str) -> List[str]:
        """Extract prerequisites from text"""
        prereqs = []

        prereq_patterns = [
            r'(?:Prerequisite|Requirement|Before|First).*?:(.*?)(?:\n|\Z)',
            r'(?:must|should|need to).*?(?:first|before|prior)',
        ]

        for pattern in prereq_patterns:
            matches = re.finditer(pattern, text, re.IGNORECASE)
            for match in matches:
                prereq = match.group(1) if match.lastindex else match.group(0)
                prereq = prereq.strip()
                if len(prereq) > 10 and len(prereq) < 200:
                    prereqs.append(prereq)

        return list(set(prereqs))[:3]

    def _extract_description(self, text: str) -> str:
        """Extract a brief description from text"""
        # Get first meaningful sentence or paragraph
        sentences = text.split('.')
        description = ""

        for sentence in sentences:
            sentence = sentence.strip()
            if len(sentence) > 30 and len(sentence) < 300:
                if not any(word in sentence.lower() for word in ['warning', 'caution', 'step']):
                    description = sentence + '.'
                    break

        if not description:
            # Fallback to first 200 chars
            description = text[:200].strip() + '...'

        return description

    def _add_exercise(self, exercise: Dict) -> None:
        """Add an exercise to the collection"""
        if exercise and exercise['id'] not in self.extracted_methods:
            self.extracted_methods[exercise['id']] = exercise
            self.extraction_stats['methods_extracted'] += 1
            logger.info(f"✅ Added exercise: {exercise['name']}")

    def _process_extracted_content(self) -> None:
        """Process and validate extracted content"""
        logger.info(f"\n{'='*50}")
        logger.info("Processing extracted content...")
        logger.info(f"{'='*50}")

        # Remove duplicates and merge similar exercises
        self._merge_similar_exercises()

        # Validate and clean data
        self._validate_exercises()

        # Add default exercises if we don't have enough
        if len(self.extracted_methods) < 20:
            self._add_default_exercises()

    def _merge_similar_exercises(self) -> None:
        """Merge exercises with similar names"""
        # Implementation for merging similar exercises
        pass

    def _validate_exercises(self) -> None:
        """Validate exercise data completeness"""
        validated = {}
        for exercise_id, exercise in self.extracted_methods.items():
            if self._is_valid_exercise(exercise):
                validated[exercise_id] = exercise
            else:
                logger.warning(f"Invalid exercise removed: {exercise.get('name', 'Unknown')}")

        self.extracted_methods = validated

    def _is_valid_exercise(self, exercise: Dict) -> bool:
        """Check if an exercise has all required fields"""
        required_fields = ['id', 'name', 'instructions', 'category']
        return all(exercise.get(field) for field in required_fields)

    def _add_default_exercises(self) -> None:
        """Add default PE exercises if extraction is insufficient"""
        default_exercises = [
            {
                'id': 'basic_jelq',
                'name': 'Basic Jelq',
                'category': 'Jelqing',
                'difficulty': 'Beginner',
                'description': 'The fundamental PE exercise for girth development.',
                'instructions': '1. Achieve 40-80% erection\n2. Form OK grip at base\n3. Slowly slide grip toward glans (3 seconds)\n4. Release before glans\n5. Repeat with other hand',
                'duration': '10-20 minutes',
                'equipment': ['Lubricant'],
                'warnings': ['Never jelq at 100% erection', 'Stop if pain occurs'],
                'prerequisites': ['2 week conditioning period'],
                'source_url': 'default',
                'source_type': 'default',
                'community_rating': 0,
                'extracted_date': datetime.now().isoformat(),
            },
            {
                'id': 'manual_stretch',
                'name': 'Manual Stretch',
                'category': 'Stretching',
                'difficulty': 'Beginner',
                'description': 'Basic manual stretching for length development.',
                'instructions': '1. Grip behind glans when flaccid\n2. Pull outward with moderate force\n3. Hold for 30 seconds\n4. Release and repeat in different directions',
                'duration': '5-10 minutes',
                'equipment': [],
                'warnings': ['Do not grip glans directly', 'Stop if numbness occurs'],
                'prerequisites': [],
                'source_url': 'default',
                'source_type': 'default',
                'community_rating': 0,
                'extracted_date': datetime.now().isoformat(),
            },
        ]

        for exercise in default_exercises:
            if exercise['id'] not in self.extracted_methods:
                self.extracted_methods[exercise['id']] = exercise
                logger.info(f"Added default exercise: {exercise['name']}")

    def _save_results(self) -> None:
        """Save extraction results to JSON file"""
        logger.info(f"\n{'='*50}")
        logger.info("Saving results...")
        logger.info(f"{'='*50}")

        # Prepare output
        output = {
            'metadata': {
                'extraction_date': datetime.now().isoformat(),
                'total_exercises': len(self.extracted_methods),
                'sources': TARGET_SUBREDDITS,
                'statistics': self.extraction_stats
            },
            'exercises': list(self.extracted_methods.values())
        }

        # Save main file
        output_file = OUTPUT_CONFIG['output_dir'] / OUTPUT_CONFIG['pe_database_file']
        with open(output_file, 'w') as f:
            json.dump(output, f, indent=2)

        logger.info(f"✅ Saved {len(self.extracted_methods)} exercises to {output_file}")

        # Create backup
        backup_file = OUTPUT_CONFIG['backup_dir'] / f"pe_database_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(backup_file, 'w') as f:
            json.dump(output, f, indent=2)

        logger.info(f"✅ Backup saved to {backup_file}")

        # Save extraction report
        self._save_extraction_report()

    def _save_extraction_report(self) -> None:
        """Save detailed extraction report"""
        report = []
        report.append("="*60)
        report.append("PE CONTENT EXTRACTION REPORT")
        report.append("="*60)
        report.append(f"Extraction Date: {datetime.now().isoformat()}")
        report.append(f"Total Exercises Extracted: {len(self.extracted_methods)}")
        report.append(f"Wikis Processed: {self.extraction_stats['wikis_processed']}")
        report.append(f"Posts Processed: {self.extraction_stats['posts_processed']}")
        report.append(f"Errors Encountered: {self.extraction_stats['errors']}")
        report.append("")

        # Category breakdown
        report.append("EXERCISES BY CATEGORY:")
        categories = {}
        for exercise in self.extracted_methods.values():
            cat = exercise.get('category', 'Unknown')
            categories[cat] = categories.get(cat, 0) + 1

        for cat, count in sorted(categories.items()):
            report.append(f"  - {cat}: {count}")

        report.append("")
        report.append("EXERCISES BY DIFFICULTY:")
        difficulties = {}
        for exercise in self.extracted_methods.values():
            diff = exercise.get('difficulty', 'Unknown')
            difficulties[diff] = difficulties.get(diff, 0) + 1

        for diff, count in sorted(difficulties.items()):
            report.append(f"  - {diff}: {count}")

        report.append("")
        report.append("EXERCISE LIST:")
        for exercise in sorted(self.extracted_methods.values(), key=lambda x: x['name']):
            report.append(f"  • {exercise['name']} ({exercise['category']}) - {exercise['difficulty']}")

        # Save report
        report_file = OUTPUT_CONFIG['output_dir'] / 'extraction_report.txt'
        with open(report_file, 'w') as f:
            f.write('\n'.join(report))

        logger.info(f"✅ Report saved to {report_file}")


def main():
    """Main execution function"""
    print("="*60)
    print("PE CONTENT EXTRACTION SYSTEM")
    print("="*60)

    try:
        extractor = PEContentExtractor()
        results = extractor.extract_all_content()

        print(f"\n✅ Extraction completed successfully!")
        print(f"Total exercises extracted: {len(results)}")

    except Exception as e:
        print(f"\n❌ Extraction failed: {e}")
        logger.error(f"Fatal error: {e}", exc_info=True)
        return 1

    return 0


if __name__ == "__main__":
    exit(main())