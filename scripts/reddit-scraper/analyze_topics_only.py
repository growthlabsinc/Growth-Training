#!/usr/bin/env python3
"""
Reddit Topic Analysis Script
Analyzes Reddit PE communities for topic trends WITHOUT extracting content.
Only analyzes titles, tags, and engagement metrics to identify patterns.
"""

import json
import os
import time
import re
from collections import Counter, defaultdict
from datetime import datetime
from typing import Dict, List, Set, Tuple

import praw
from dotenv import load_dotenv

# Import existing configuration
from reddit_config import REDDIT_CONFIG, RATE_LIMIT

# Load environment variables
load_dotenv()

# CRITICAL: No content extraction allowed - titles and metadata only
ANALYSIS_CONFIG = {
    'posts_per_category': 500,  # For primary communities
    'posts_per_secondary': 250,  # For secondary communities
    'rate_limit_delay': 2,  # Seconds between API calls
    'primary_communities': ['TheScienceOfPE', 'GettingBigger'],
    'secondary_communities': ['AJelqForYou', 'PEGym'],
    'categories': ['hot', 'new', 'top'],
    'time_filters': ['all', 'year', 'month']
}

# Topic categories for classification
TOPIC_CATEGORIES = {
    'science_research': ['science', 'study', 'research', 'evidence', 'data', 'medical', 'biological'],
    'safety_health': ['safe', 'safety', 'injury', 'pain', 'damage', 'risk', 'doctor', 'medical'],
    'technique_method': ['technique', 'method', 'exercise', 'routine', 'jelq', 'stretch', 'pump', 'hang'],
    'progress_measurement': ['progress', 'gains', 'growth', 'measure', 'size', 'length', 'girth', 'results'],
    'equipment_tools': ['device', 'equipment', 'pump', 'hanger', 'extender', 'tool', 'gear'],
    'nutrition_supplements': ['supplement', 'vitamin', 'nutrition', 'diet', 'food', 'citrulline', 'arginine'],
    'recovery_rest': ['rest', 'recovery', 'decon', 'break', 'off day', 'heal', 'repair'],
    'beginner_guidance': ['beginner', 'newbie', 'start', 'first', 'new to', 'help', 'guide', 'basics']
}

# Question patterns to identify user needs
QUESTION_PATTERNS = {
    'how': r'\bhow\s+(to|do|can|should|much|long|often)\b',
    'what': r'\bwhat\s+(is|are|should|can|does|do)\b',
    'why': r'\bwhy\s+(is|are|do|does|should|would)\b',
    'when': r'\bwhen\s+(to|should|do|does|can|will)\b',
    'which': r'\bwhich\s+(is|are|should|one|method|technique)\b',
    'should': r'\bshould\s+i\b',
    'can': r'\bcan\s+(i|you|anyone)\b',
    'is_it': r'\bis\s+it\s+(safe|possible|normal|okay|worth)\b'
}


class RedditTopicAnalyzer:
    """Analyzes Reddit topics without extracting content"""

    def __init__(self):
        """Initialize Reddit API connection"""
        self.reddit = praw.Reddit(
            client_id=os.getenv('REDDIT_CLIENT_ID'),
            client_secret=os.getenv('REDDIT_CLIENT_SECRET'),
            user_agent=os.getenv('REDDIT_USER_AGENT', 'TopicAnalyzer/1.0')
        )

        self.topic_data = defaultdict(lambda: {
            'frequency': 0,
            'total_score': 0,
            'total_comments': 0,
            'questions': [],
            'categories': Counter(),
            'flairs': Counter()
        })

        self.keyword_frequency = Counter()
        self.question_types = Counter()
        self.user_journey_stage = defaultdict(list)

    def analyze_title(self, title: str, score: int, num_comments: int, flair: str = None) -> None:
        """
        Analyze a post title for topics and patterns.
        NO CONTENT EXTRACTION - titles only!
        """
        title_lower = title.lower()

        # Extract keywords (3+ characters, exclude common words)
        words = re.findall(r'\b[a-z]{3,}\b', title_lower)
        stop_words = {'the', 'and', 'for', 'with', 'this', 'that', 'from', 'have', 'been', 'are', 'was', 'were'}
        keywords = [w for w in words if w not in stop_words]

        # Update keyword frequency
        self.keyword_frequency.update(keywords)

        # Categorize topic
        for category, terms in TOPIC_CATEGORIES.items():
            if any(term in title_lower for term in terms):
                self.topic_data[category]['frequency'] += 1
                self.topic_data[category]['total_score'] += score
                self.topic_data[category]['total_comments'] += num_comments
                if flair:
                    self.topic_data[category]['flairs'][flair] += 1

        # Identify question patterns
        for q_type, pattern in QUESTION_PATTERNS.items():
            if re.search(pattern, title_lower):
                self.question_types[q_type] += 1

                # Determine user journey stage
                if 'beginner' in title_lower or 'newbie' in title_lower or 'start' in title_lower:
                    self.user_journey_stage['beginner'].append(q_type)
                elif 'advanced' in title_lower or 'veteran' in title_lower:
                    self.user_journey_stage['advanced'].append(q_type)
                else:
                    self.user_journey_stage['intermediate'].append(q_type)

    def analyze_subreddit(self, subreddit_name: str, post_limit: int) -> Dict:
        """
        Analyze a single subreddit for topic patterns.
        Returns analysis summary WITHOUT any post content.
        """
        print(f"\nAnalyzing r/{subreddit_name}...")
        subreddit = self.reddit.subreddit(subreddit_name)

        posts_analyzed = 0
        subreddit_stats = {
            'total_posts': 0,
            'avg_score': 0,
            'avg_comments': 0,
            'top_flairs': Counter(),
            'category_distribution': defaultdict(int)
        }

        # Analyze posts from different categories
        for category in ANALYSIS_CONFIG['categories']:
            print(f"  Fetching {category} posts...")

            try:
                if category == 'hot':
                    submissions = subreddit.hot(limit=post_limit // 3)
                elif category == 'new':
                    submissions = subreddit.new(limit=post_limit // 3)
                else:  # top
                    submissions = subreddit.top(time_filter='year', limit=post_limit // 3)

                for submission in submissions:
                    # CRITICAL: Only analyze title and metadata, NO content extraction
                    self.analyze_title(
                        title=submission.title,
                        score=submission.score,
                        num_comments=submission.num_comments,
                        flair=submission.link_flair_text
                    )

                    # Update subreddit stats
                    subreddit_stats['total_posts'] += 1
                    subreddit_stats['avg_score'] += submission.score
                    subreddit_stats['avg_comments'] += submission.num_comments
                    if submission.link_flair_text:
                        subreddit_stats['top_flairs'][submission.link_flair_text] += 1

                    posts_analyzed += 1

                    # Rate limiting
                    if posts_analyzed % 10 == 0:
                        time.sleep(ANALYSIS_CONFIG['rate_limit_delay'])
                        print(f"    Analyzed {posts_analyzed} posts...")

                    if posts_analyzed >= post_limit:
                        break

                if posts_analyzed >= post_limit:
                    break

            except Exception as e:
                print(f"  Error analyzing {category} posts: {e}")

        # Calculate averages
        if subreddit_stats['total_posts'] > 0:
            subreddit_stats['avg_score'] /= subreddit_stats['total_posts']
            subreddit_stats['avg_comments'] /= subreddit_stats['total_posts']

        print(f"  Completed: {posts_analyzed} posts analyzed")
        return subreddit_stats

    def generate_analysis_report(self) -> Dict:
        """
        Generate comprehensive analysis report.
        Contains ONLY patterns and statistics, NO Reddit content.
        """

        # Get top keywords (excluding those already in categories)
        category_terms = set()
        for terms in TOPIC_CATEGORIES.values():
            category_terms.update(terms)

        top_keywords = [
            (word, count) for word, count in self.keyword_frequency.most_common(50)
            if word not in category_terms
        ]

        # Calculate topic priorities based on frequency and engagement
        topic_priorities = []
        for topic, data in self.topic_data.items():
            if data['frequency'] > 0:
                avg_score = data['total_score'] / data['frequency']
                avg_comments = data['total_comments'] / data['frequency']
                engagement_score = (avg_score * 0.3 + avg_comments * 0.7) * data['frequency']

                topic_priorities.append({
                    'topic': topic,
                    'frequency': data['frequency'],
                    'avg_score': avg_score,
                    'avg_comments': avg_comments,
                    'engagement_score': engagement_score,
                    'top_flairs': data['flairs'].most_common(5)
                })

        # Sort by engagement score
        topic_priorities.sort(key=lambda x: x['engagement_score'], reverse=True)

        return {
            'analysis_timestamp': datetime.now().isoformat(),
            'topic_priorities': topic_priorities[:15],  # Top 15 topics
            'keyword_frequency': dict(top_keywords[:30]),
            'question_patterns': dict(self.question_types),
            'user_journey_distribution': {
                stage: Counter(questions).most_common()
                for stage, questions in self.user_journey_stage.items()
            },
            'total_posts_analyzed': sum(data['frequency'] for data in self.topic_data.values())
        }

    def run_analysis(self) -> None:
        """Execute complete analysis workflow"""
        print("Starting Reddit Topic Analysis (NO CONTENT EXTRACTION)")
        print("=" * 60)

        all_stats = {}

        # Analyze primary communities
        for subreddit in ANALYSIS_CONFIG['primary_communities']:
            stats = self.analyze_subreddit(subreddit, ANALYSIS_CONFIG['posts_per_category'])
            all_stats[subreddit] = stats
            time.sleep(ANALYSIS_CONFIG['rate_limit_delay'] * 2)  # Extra delay between subreddits

        # Analyze secondary communities
        for subreddit in ANALYSIS_CONFIG['secondary_communities']:
            stats = self.analyze_subreddit(subreddit, ANALYSIS_CONFIG['posts_per_secondary'])
            all_stats[subreddit] = stats
            time.sleep(ANALYSIS_CONFIG['rate_limit_delay'] * 2)

        # Generate final report
        report = self.generate_analysis_report()
        report['subreddit_stats'] = all_stats

        # Save analysis results
        output_dir = 'extracted_data'
        os.makedirs(output_dir, exist_ok=True)

        output_file = os.path.join(output_dir, 'topic_analysis.json')
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)

        print(f"\n✅ Analysis complete! Results saved to: {output_file}")
        print(f"Total topics identified: {len(report['topic_priorities'])}")
        print(f"Total posts analyzed: {report['total_posts_analyzed']}")
        print("\n⚠️  REMINDER: This analysis contains NO Reddit content, only patterns and statistics.")


def main():
    """Main execution function"""
    analyzer = RedditTopicAnalyzer()
    analyzer.run_analysis()


if __name__ == '__main__':
    main()