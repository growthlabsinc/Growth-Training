#!/usr/bin/env python3
"""
Vendor Post Analysis for r/TheScienceofPE
Identifies and analyzes vendor/product introduction posts with high engagement
Develops posting style recommendations for Growth Training app introduction
"""

import praw
import json
import os
from datetime import datetime, timedelta
from collections import Counter, defaultdict
import re
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
load_dotenv()

# Reddit API configuration
reddit = praw.Reddit(
    client_id=os.getenv('REDDIT_CLIENT_ID'),
    client_secret=os.getenv('REDDIT_CLIENT_SECRET'),
    user_agent=os.getenv('REDDIT_USER_AGENT', 'Growth_Training_Research/1.0')
)

# Target subreddit
TARGET_SUBREDDIT = 'TheScienceOfPE'

# Keywords for vendor/product posts
VENDOR_KEYWORDS = [
    'app', 'tool', 'website', 'service', 'platform', 'product',
    'introducing', 'launched', 'created', 'built', 'developed',
    'new', 'announcement', 'release', 'available'
]

# Engagement thresholds for "high engagement"
HIGH_ENGAGEMENT_THRESHOLDS = {
    'min_score': 20,  # Minimum upvotes
    'min_comments': 10,  # Minimum comment count
    'min_upvote_ratio': 0.70  # At least 70% upvote ratio
}


class VendorPostAnalyzer:
    """Analyzes vendor introduction posts and their engagement patterns"""

    def __init__(self):
        self.subreddit = reddit.subreddit(TARGET_SUBREDDIT)
        self.vendor_posts = []
        self.high_engagement_posts = []
        self.analysis = {
            'subreddit': TARGET_SUBREDDIT,
            'scan_date': datetime.now().isoformat(),
            'total_posts_scanned': 0,
            'vendor_posts_found': 0,
            'high_engagement_posts': 0,
            'engagement_analysis': {},
            'style_patterns': {},
            'content_structure': {},
            'timing_patterns': {},
            'recommendations': []
        }

    def scan_subreddit(self, time_filter='all', limit=500):
        """Scan subreddit for vendor posts"""
        print(f"\n🔍 Scanning r/{TARGET_SUBREDDIT} for vendor posts...")
        print(f"   Time filter: {time_filter}, Limit: {limit}")

        # Scan top posts
        print("\n  📊 Scanning top posts...")
        for submission in self.subreddit.top(time_filter=time_filter, limit=limit):
            self._process_submission(submission)

        # Also scan new posts to get recent examples
        print("\n  🆕 Scanning recent posts...")
        for submission in self.subreddit.new(limit=200):
            self._process_submission(submission)

        self.analysis['total_posts_scanned'] = len(self.vendor_posts)
        print(f"\n✅ Found {len(self.vendor_posts)} potential vendor posts")
        print(f"   {len(self.high_engagement_posts)} with high engagement")

    def _process_submission(self, submission):
        """Process a single submission"""
        # Skip if already processed
        if any(p['id'] == submission.id for p in self.vendor_posts):
            return

        # Check if it's a vendor/product post
        if not self._is_vendor_post(submission):
            return

        post_data = {
            'id': submission.id,
            'title': submission.title,
            'body': submission.selftext if submission.is_self else '',
            'author': str(submission.author) if submission.author else '[deleted]',
            'score': submission.score,
            'upvote_ratio': submission.upvote_ratio,
            'num_comments': submission.num_comments,
            'created_utc': datetime.fromtimestamp(submission.created_utc).isoformat(),
            'created_date': datetime.fromtimestamp(submission.created_utc).strftime('%Y-%m-%d'),
            'day_of_week': datetime.fromtimestamp(submission.created_utc).strftime('%A'),
            'url': f"https://reddit.com{submission.permalink}",
            'flair': submission.link_flair_text,
            'is_self': submission.is_self,
            'awards_received': submission.total_awards_received if hasattr(submission, 'total_awards_received') else 0,
            'is_high_engagement': self._is_high_engagement(submission)
        }

        self.vendor_posts.append(post_data)
        self.analysis['vendor_posts_found'] += 1

        if post_data['is_high_engagement']:
            self.high_engagement_posts.append(post_data)
            self.analysis['high_engagement_posts'] += 1

    def _is_vendor_post(self, submission):
        """Determine if a post is a vendor/product introduction"""
        text = f"{submission.title} {submission.selftext}".lower()

        # Must contain at least one vendor keyword
        has_vendor_keyword = any(keyword in text for keyword in VENDOR_KEYWORDS)

        # Additional indicators
        has_link = bool(submission.url and not submission.is_self)
        mentions_creating = any(word in text for word in ['i built', 'i created', 'i made', 'i developed', 'we built', 'we created'])
        is_announcement = any(word in text for word in ['announcing', 'introducing', 'pleased to', 'excited to'])

        # Product/tool specific mentions
        is_product_related = any(word in text for word in ['app', 'tool', 'website', 'tracker', 'calculator', 'guide', 'program'])

        return has_vendor_keyword and (mentions_creating or is_announcement or is_product_related)

    def _is_high_engagement(self, submission):
        """Determine if post has high engagement"""
        return (submission.score >= HIGH_ENGAGEMENT_THRESHOLDS['min_score'] and
                submission.num_comments >= HIGH_ENGAGEMENT_THRESHOLDS['min_comments'] and
                submission.upvote_ratio >= HIGH_ENGAGEMENT_THRESHOLDS['min_upvote_ratio'])

    def analyze_engagement_patterns(self):
        """Analyze what makes vendor posts successful"""
        print("\n📊 Analyzing engagement patterns...")

        if not self.high_engagement_posts:
            print("  ⚠️ No high-engagement posts found for analysis")
            return

        # Sort by engagement score (combined metric)
        sorted_posts = sorted(
            self.high_engagement_posts,
            key=lambda x: x['score'] * (1 + x['num_comments']/10),
            reverse=True
        )

        # Engagement statistics
        scores = [p['score'] for p in self.high_engagement_posts]
        comments = [p['num_comments'] for p in self.high_engagement_posts]
        ratios = [p['upvote_ratio'] for p in self.high_engagement_posts]

        self.analysis['engagement_analysis'] = {
            'avg_score': sum(scores) / len(scores),
            'max_score': max(scores),
            'avg_comments': sum(comments) / len(comments),
            'max_comments': max(comments),
            'avg_upvote_ratio': sum(ratios) / len(ratios),
            'top_posts': sorted_posts[:10]  # Top 10 posts
        }

        print(f"  Average score: {self.analysis['engagement_analysis']['avg_score']:.1f}")
        print(f"  Average comments: {self.analysis['engagement_analysis']['avg_comments']:.1f}")
        print(f"  Average upvote ratio: {self.analysis['engagement_analysis']['avg_upvote_ratio']:.2%}")

    def analyze_content_structure(self):
        """Analyze the structure and style of high-engagement posts"""
        print("\n📝 Analyzing content structure...")

        if not self.high_engagement_posts:
            return

        # Analyze titles
        title_lengths = [len(p['title']) for p in self.high_engagement_posts]
        title_patterns = self._extract_title_patterns()

        # Analyze body content
        body_lengths = [len(p['body']) for p in self.high_engagement_posts if p['body']]
        body_structures = self._extract_body_structures()

        # Common words in successful posts
        all_text = ' '.join([f"{p['title']} {p['body']}" for p in self.high_engagement_posts])
        words = re.findall(r'\b[a-zA-Z]{4,}\b', all_text.lower())
        common_words = Counter(words).most_common(30)

        self.analysis['content_structure'] = {
            'avg_title_length': sum(title_lengths) / len(title_lengths) if title_lengths else 0,
            'title_patterns': title_patterns,
            'avg_body_length': sum(body_lengths) / len(body_lengths) if body_lengths else 0,
            'body_structures': body_structures,
            'common_words': common_words
        }

        print(f"  Average title length: {self.analysis['content_structure']['avg_title_length']:.0f} chars")
        print(f"  Average body length: {self.analysis['content_structure']['avg_body_length']:.0f} chars")

    def _extract_title_patterns(self):
        """Extract common patterns in successful titles"""
        patterns = {
            'starts_with_question': 0,
            'contains_brackets': 0,
            'contains_exclamation': 0,
            'mentions_free': 0,
            'mentions_new': 0,
            'contains_number': 0,
            'all_caps_words': 0
        }

        for post in self.high_engagement_posts:
            title = post['title']
            if title.startswith(('What', 'How', 'Why', 'When', 'Where', 'Who', 'Which', 'Is', 'Are', 'Can', 'Do', 'Does')):
                patterns['starts_with_question'] += 1
            if '[' in title or ']' in title:
                patterns['contains_brackets'] += 1
            if '!' in title:
                patterns['contains_exclamation'] += 1
            if 'free' in title.lower():
                patterns['mentions_free'] += 1
            if 'new' in title.lower():
                patterns['mentions_new'] += 1
            if re.search(r'\d+', title):
                patterns['contains_number'] += 1
            if re.search(r'\b[A-Z]{2,}\b', title):
                patterns['all_caps_words'] += 1

        return patterns

    def _extract_body_structures(self):
        """Extract common structural elements in post bodies"""
        structures = {
            'has_bullet_points': 0,
            'has_numbered_list': 0,
            'has_headers': 0,
            'has_links': 0,
            'has_bold_text': 0,
            'has_italic_text': 0,
            'has_code_blocks': 0,
            'has_quotes': 0,
            'paragraph_count': []
        }

        for post in self.high_engagement_posts:
            body = post['body']
            if not body:
                continue

            if '* ' in body or '- ' in body:
                structures['has_bullet_points'] += 1
            if re.search(r'^\d+\.', body, re.MULTILINE):
                structures['has_numbered_list'] += 1
            if '#' in body:
                structures['has_headers'] += 1
            if 'http' in body or '[' in body and '](' in body:
                structures['has_links'] += 1
            if '**' in body:
                structures['has_bold_text'] += 1
            if '*' in body or '_' in body:
                structures['has_italic_text'] += 1
            if '```' in body or '`' in body:
                structures['has_code_blocks'] += 1
            if '>' in body:
                structures['has_quotes'] += 1

            # Count paragraphs
            paragraphs = [p for p in body.split('\n\n') if p.strip()]
            structures['paragraph_count'].append(len(paragraphs))

        # Calculate average paragraph count
        if structures['paragraph_count']:
            structures['avg_paragraphs'] = sum(structures['paragraph_count']) / len(structures['paragraph_count'])
        else:
            structures['avg_paragraphs'] = 0

        return structures

    def analyze_timing_patterns(self):
        """Analyze when high-engagement posts were made"""
        print("\n⏰ Analyzing timing patterns...")

        if not self.high_engagement_posts:
            return

        # Day of week distribution
        day_counts = Counter([p['day_of_week'] for p in self.high_engagement_posts])

        # Time of day (would need hour info, but we can infer from UTC)
        # Most Reddit posts do well posted between 8am-2pm EST (12pm-6pm UTC)

        self.analysis['timing_patterns'] = {
            'day_of_week_distribution': dict(day_counts),
            'most_common_day': day_counts.most_common(1)[0] if day_counts else None
        }

        print(f"  Day of week distribution: {dict(day_counts)}")

    def generate_recommendations(self):
        """Generate specific recommendations for Growth Training post"""
        print("\n💡 Generating recommendations...")

        recommendations = []

        # Title recommendations
        if self.analysis['content_structure']:
            avg_title_len = self.analysis['content_structure']['avg_title_length']
            recommendations.append({
                'category': 'Title',
                'recommendation': f"Keep title around {avg_title_len:.0f} characters",
                'reasoning': 'Matches successful vendor posts'
            })

            title_patterns = self.analysis['content_structure']['title_patterns']
            if title_patterns.get('contains_brackets', 0) > len(self.high_engagement_posts) / 2:
                recommendations.append({
                    'category': 'Title',
                    'recommendation': 'Consider using brackets [like this] to highlight key info',
                    'reasoning': 'Common in high-engagement posts'
                })

        # Body structure recommendations
        if self.analysis['content_structure'].get('body_structures'):
            structures = self.analysis['content_structure']['body_structures']

            if structures['has_bullet_points'] > len(self.high_engagement_posts) / 2:
                recommendations.append({
                    'category': 'Body Structure',
                    'recommendation': 'Use bullet points to list features/benefits',
                    'reasoning': 'Improves readability and scan-ability'
                })

            if structures['has_bold_text'] > len(self.high_engagement_posts) / 2:
                recommendations.append({
                    'category': 'Body Structure',
                    'recommendation': 'Use **bold text** to emphasize key points',
                    'reasoning': 'Helps readers quickly identify important information'
                })

            if structures.get('avg_paragraphs', 0) > 0:
                recommendations.append({
                    'category': 'Body Structure',
                    'recommendation': f"Structure post with {structures['avg_paragraphs']:.0f} clear sections/paragraphs",
                    'reasoning': 'Matches successful vendor posts'
                })

        # Engagement recommendations
        if self.analysis['engagement_analysis']:
            recommendations.append({
                'category': 'Engagement',
                'recommendation': 'Respond to ALL comments quickly and professionally',
                'reasoning': 'Builds trust and shows you care about community feedback'
            })

            recommendations.append({
                'category': 'Engagement',
                'recommendation': 'Ask for feedback explicitly in your post',
                'reasoning': 'Encourages comments and community participation'
            })

        # Community-specific recommendations
        recommendations.extend([
            {
                'category': 'Community Guidelines',
                'recommendation': 'Acknowledge moderator approval from u/karlwikman',
                'reasoning': 'Shows respect for community rules and transparency'
            },
            {
                'category': 'Community Guidelines',
                'recommendation': 'Focus on how app helps PE journey, not just features',
                'reasoning': 'Community values practical benefits over technical specs'
            },
            {
                'category': 'Value Proposition',
                'recommendation': 'Offer something free or valuable (trial, guide, etc.)',
                'reasoning': 'Reduces barrier to entry and builds goodwill'
            },
            {
                'category': 'Transparency',
                'recommendation': 'Be upfront about being the developer',
                'reasoning': 'Honesty builds trust in this community'
            },
            {
                'category': 'Timing',
                'recommendation': 'Post on weekdays (Tuesday-Thursday) between 9am-2pm EST',
                'reasoning': 'Higher Reddit activity during these times'
            }
        ])

        self.analysis['recommendations'] = recommendations

        print(f"\n✅ Generated {len(recommendations)} recommendations")
        for rec in recommendations:
            print(f"  • [{rec['category']}] {rec['recommendation']}")

    def create_example_post(self):
        """Create an example post based on analysis"""
        print("\n📄 Creating example post structure...")

        example = {
            'title_options': [
                "[New App] Growth Training - PE Progress Tracking & Routine Management (Free Beta)",
                "I built Growth Training - A PE App for Tracking Progress & Managing Routines [Mod Approved]",
                "Introducing Growth Training: Free PE Tracking App for r/TheScienceofPE Community"
            ],
            'body_structure': {
                'intro': "Hey everyone! With mod u/karlwikman's permission, I wanted to share an app I've been building for the PE community...",
                'sections': [
                    {
                        'header': '## What is Growth Training?',
                        'content': 'Brief description focusing on benefits, not features'
                    },
                    {
                        'header': '## Key Features',
                        'content': 'Bullet point list of main features'
                    },
                    {
                        'header': '## Why I Built This',
                        'content': 'Personal story/motivation - connects with community'
                    },
                    {
                        'header': '## Community Feedback Wanted',
                        'content': 'Specific questions to encourage engagement'
                    },
                    {
                        'header': '## Getting Started',
                        'content': 'Clear call-to-action with links'
                    }
                ],
                'outro': 'Thanks for reading! Happy to answer any questions.'
            },
            'tone_guidelines': [
                'Humble and genuine',
                'Focus on community benefit',
                'Ask for feedback',
                'Be responsive in comments',
                'Show you understand PE principles'
            ]
        }

        self.analysis['example_post'] = example
        print("  ✅ Example post structure created")

    def save_analysis(self, output_dir='extracted_data'):
        """Save analysis to JSON file"""
        output_path = Path(output_dir)
        output_path.mkdir(exist_ok=True)

        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = output_path / f'vendor_post_analysis_{timestamp}.json'

        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.analysis, f, indent=2, ensure_ascii=False)

        print(f"\n💾 Analysis saved to: {filename}")

        # Also save a human-readable report
        report_filename = output_path / f'vendor_post_report_{timestamp}.txt'
        self._save_report(report_filename)

        return filename

    def _save_report(self, filename):
        """Save a human-readable report"""
        with open(filename, 'w', encoding='utf-8') as f:
            f.write("=" * 80 + "\n")
            f.write("VENDOR POST ANALYSIS REPORT\n")
            f.write(f"r/{TARGET_SUBREDDIT}\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("=" * 80 + "\n\n")

            # Summary
            f.write("SUMMARY\n")
            f.write("-" * 80 + "\n")
            f.write(f"Total posts scanned: {self.analysis['total_posts_scanned']}\n")
            f.write(f"Vendor posts found: {self.analysis['vendor_posts_found']}\n")
            f.write(f"High engagement posts: {self.analysis['high_engagement_posts']}\n\n")

            # Top posts
            if self.analysis.get('engagement_analysis', {}).get('top_posts'):
                f.write("\nTOP PERFORMING VENDOR POSTS\n")
                f.write("-" * 80 + "\n")
                for i, post in enumerate(self.analysis['engagement_analysis']['top_posts'][:5], 1):
                    f.write(f"\n{i}. {post['title']}\n")
                    f.write(f"   Score: {post['score']} | Comments: {post['num_comments']} | Ratio: {post['upvote_ratio']:.0%}\n")
                    f.write(f"   Author: u/{post['author']} | Date: {post['created_date']}\n")
                    f.write(f"   URL: {post['url']}\n")

            # Recommendations
            if self.analysis.get('recommendations'):
                f.write("\n\nRECOMMENDATIONS FOR GROWTH TRAINING POST\n")
                f.write("-" * 80 + "\n")
                for rec in self.analysis['recommendations']:
                    f.write(f"\n[{rec['category']}]\n")
                    f.write(f"  • {rec['recommendation']}\n")
                    f.write(f"    Reasoning: {rec['reasoning']}\n")

            # Example post structure
            if self.analysis.get('example_post'):
                f.write("\n\nEXAMPLE POST STRUCTURE\n")
                f.write("-" * 80 + "\n")
                example = self.analysis['example_post']

                f.write("\nTitle Options:\n")
                for i, title in enumerate(example['title_options'], 1):
                    f.write(f"  {i}. {title}\n")

                f.write("\nBody Structure:\n")
                f.write(f"  Introduction: {example['body_structure']['intro']}\n\n")
                for section in example['body_structure']['sections']:
                    f.write(f"  {section['header']}\n")
                    f.write(f"  {section['content']}\n\n")
                f.write(f"  Outro: {example['body_structure']['outro']}\n")

                f.write("\nTone Guidelines:\n")
                for guideline in example['tone_guidelines']:
                    f.write(f"  • {guideline}\n")

        print(f"  💾 Report saved to: {filename}")

    def run_full_analysis(self):
        """Run the complete analysis pipeline"""
        print("\n" + "=" * 80)
        print("VENDOR POST ANALYSIS FOR r/TheScienceofPE")
        print("=" * 80)

        # Scan subreddit
        self.scan_subreddit(time_filter='all', limit=500)

        if not self.vendor_posts:
            print("\n⚠️ No vendor posts found. Try adjusting search parameters.")
            return

        # Run analyses
        self.analyze_engagement_patterns()
        self.analyze_content_structure()
        self.analyze_timing_patterns()
        self.generate_recommendations()
        self.create_example_post()

        # Save results
        self.save_analysis()

        print("\n" + "=" * 80)
        print("ANALYSIS COMPLETE!")
        print("=" * 80)
        print(f"\n📊 Summary:")
        print(f"   • Found {self.analysis['vendor_posts_found']} vendor posts")
        print(f"   • {self.analysis['high_engagement_posts']} with high engagement")
        print(f"   • Generated {len(self.analysis['recommendations'])} recommendations")
        print("\n✅ Ready to craft your Growth Training introduction post!")


def main():
    """Main execution"""
    analyzer = VendorPostAnalyzer()
    analyzer.run_full_analysis()


if __name__ == '__main__':
    main()
