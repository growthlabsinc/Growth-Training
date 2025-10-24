#!/usr/bin/env python3
"""
Reddit User Style Analysis
Analyzes specific users' posting and commenting patterns to develop communication guidelines
"""

import praw
import json
import os
from datetime import datetime
from collections import Counter, defaultdict
import re
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Reddit API configuration
reddit = praw.Reddit(
    client_id=os.getenv('REDDIT_CLIENT_ID'),
    client_secret=os.getenv('REDDIT_CLIENT_SECRET'),
    user_agent=os.getenv('REDDIT_USER_AGENT', 'PE_Research_Bot/1.0')
)

# Target users to analyze
TARGET_USERS = ['karlwikman', 'pervmcswerve']

# PE-related subreddits for context
PE_SUBREDDITS = [
    'GettingBigger',
    'AJelqForYou',
    'PEGym',
    'TheScienceOfPE'
]


class UserStyleAnalyzer:
    """Analyzes Reddit user communication style and patterns"""

    def __init__(self, username):
        self.username = username
        self.user = reddit.redditor(username)
        self.posts = []
        self.comments = []
        self.analysis = {
            'username': username,
            'profile': {},
            'posting_patterns': {},
            'commenting_patterns': {},
            'communication_style': {},
            'vocabulary_analysis': {},
            'engagement_metrics': {},
            'topic_distribution': {},
            'tone_indicators': {},
            'interaction_style': {},
            'best_practices': [],
            'content_examples': {
                'posts': [],
                'comments': []
            }
        }

    def gather_user_data(self, limit=200):
        """Collect user's posts and comments"""
        print(f"\n🔍 Gathering data for u/{self.username}...")

        try:
            # Collect profile information
            self.analysis['profile'] = {
                'created_utc': datetime.fromtimestamp(self.user.created_utc).isoformat(),
                'link_karma': self.user.link_karma,
                'comment_karma': self.user.comment_karma,
                'total_karma': self.user.link_karma + self.user.comment_karma,
                'account_age_days': (datetime.now() - datetime.fromtimestamp(self.user.created_utc)).days,
                'is_gold': self.user.is_gold if hasattr(self.user, 'is_gold') else False
            }

            # Collect submissions (posts)
            print(f"  📝 Collecting posts...")
            for submission in self.user.submissions.new(limit=limit):
                post_data = {
                    'title': submission.title,
                    'body': submission.selftext if submission.is_self else None,
                    'subreddit': str(submission.subreddit),
                    'score': submission.score,
                    'num_comments': submission.num_comments,
                    'created_utc': datetime.fromtimestamp(submission.created_utc).isoformat(),
                    'url': submission.url,
                    'flair': submission.link_flair_text,
                    'is_self': submission.is_self,
                    'upvote_ratio': submission.upvote_ratio
                }
                self.posts.append(post_data)

            print(f"  ✅ Collected {len(self.posts)} posts")

            # Collect comments
            print(f"  💬 Collecting comments...")
            for comment in self.user.comments.new(limit=limit):
                comment_data = {
                    'body': comment.body,
                    'subreddit': str(comment.subreddit),
                    'score': comment.score,
                    'created_utc': datetime.fromtimestamp(comment.created_utc).isoformat(),
                    'parent_type': 'submission' if comment.is_root else 'comment',
                    'depth': comment.depth if hasattr(comment, 'depth') else 0,
                    'is_submitter': comment.is_submitter
                }

                # Add parent post context if available
                try:
                    submission = comment.submission
                    comment_data['parent_post'] = {
                        'title': submission.title,
                        'subreddit': str(submission.subreddit)
                    }
                except:
                    comment_data['parent_post'] = None

                self.comments.append(comment_data)

            print(f"  ✅ Collected {len(self.comments)} comments")

        except Exception as e:
            print(f"  ❌ Error gathering data: {e}")

    def analyze_posting_patterns(self):
        """Analyze how user creates posts"""
        print(f"\n📊 Analyzing posting patterns...")

        if not self.posts:
            self.analysis['posting_patterns'] = {'note': 'No posts found'}
            return

        patterns = {
            'total_posts': len(self.posts),
            'avg_title_length': sum(len(p['title']) for p in self.posts) / len(self.posts),
            'avg_body_length': sum(len(p['body'] or '') for p in self.posts) / len(self.posts),
            'avg_score': sum(p['score'] for p in self.posts) / len(self.posts),
            'avg_comments': sum(p['num_comments'] for p in self.posts) / len(self.posts),
            'subreddit_distribution': dict(Counter(p['subreddit'] for p in self.posts)),
            'flair_distribution': dict(Counter(p['flair'] for p in self.posts if p['flair'])),
            'self_post_ratio': sum(1 for p in self.posts if p['is_self']) / len(self.posts),
            'avg_upvote_ratio': sum(p['upvote_ratio'] for p in self.posts) / len(self.posts)
        }

        # Analyze title patterns
        title_patterns = {
            'starts_with_question': sum(1 for p in self.posts if p['title'].strip().startswith(('?', 'How', 'What', 'Why', 'When', 'Where', 'Is', 'Are', 'Can', 'Should', 'Do', 'Does'))) / len(self.posts),
            'contains_brackets': sum(1 for p in self.posts if '[' in p['title']) / len(self.posts),
            'contains_emoji': sum(1 for p in self.posts if any(ord(c) > 127 for c in p['title'])) / len(self.posts),
            'avg_words': sum(len(p['title'].split()) for p in self.posts) / len(self.posts)
        }
        patterns['title_patterns'] = title_patterns

        self.analysis['posting_patterns'] = patterns

    def analyze_commenting_patterns(self):
        """Analyze how user comments"""
        print(f"\n💬 Analyzing commenting patterns...")

        if not self.comments:
            self.analysis['commenting_patterns'] = {'note': 'No comments found'}
            return

        patterns = {
            'total_comments': len(self.comments),
            'avg_comment_length': sum(len(c['body']) for c in self.comments) / len(self.comments),
            'avg_score': sum(c['score'] for c in self.comments) / len(self.comments),
            'subreddit_distribution': dict(Counter(c['subreddit'] for c in self.comments)),
            'root_comment_ratio': sum(1 for c in self.comments if c['parent_type'] == 'submission') / len(self.comments),
            'avg_depth': sum(c['depth'] for c in self.comments) / len(self.comments),
            'op_response_ratio': sum(1 for c in self.comments if c['is_submitter']) / len(self.comments) if len(self.comments) > 0 else 0
        }

        # Analyze comment structure
        structure_patterns = {
            'multiline_ratio': sum(1 for c in self.comments if '\n\n' in c['body']) / len(self.comments),
            'contains_bullets': sum(1 for c in self.comments if re.search(r'[\*\-\•]\s+', c['body'])) / len(self.comments),
            'contains_numbered_list': sum(1 for c in self.comments if re.search(r'\d+[\.\)]\s+', c['body'])) / len(self.comments),
            'contains_quotes': sum(1 for c in self.comments if '>' in c['body']) / len(self.comments),
            'contains_bold': sum(1 for c in self.comments if '**' in c['body']) / len(self.comments),
            'contains_italics': sum(1 for c in self.comments if '*' in c['body'] or '_' in c['body']) / len(self.comments),
            'contains_links': sum(1 for c in self.comments if 'http' in c['body']) / len(self.comments),
            'contains_code': sum(1 for c in self.comments if '`' in c['body']) / len(self.comments)
        }
        patterns['structure_patterns'] = structure_patterns

        self.analysis['commenting_patterns'] = patterns

    def analyze_vocabulary(self):
        """Analyze word choice and vocabulary"""
        print(f"\n📚 Analyzing vocabulary...")

        all_text = []
        all_text.extend([p['title'] + ' ' + (p['body'] or '') for p in self.posts])
        all_text.extend([c['body'] for c in self.comments])

        combined_text = ' '.join(all_text).lower()

        # Common PE terminology usage
        pe_terms = {
            'beginner_friendly': ['beginner', 'newbie', 'starting', 'first time', 'new to'],
            'technical': ['tension', 'erection quality', 'eq', 'tunica', 'corpus', 'ligament'],
            'safety': ['injury', 'pain', 'safe', 'careful', 'slowly', 'gradually', 'listen to your body'],
            'measurement': ['gains', 'progress', 'measure', 'tracking', 'growth', 'size'],
            'techniques': ['jelq', 'stretch', 'pump', 'hang', 'clamp', 'manual', 'device'],
            'time_frequency': ['daily', 'weekly', 'months', 'years', 'session', 'routine', 'rest day'],
            'encouragement': ['keep going', "don't give up", 'patience', 'consistent', 'trust the process']
        }

        term_usage = {}
        for category, terms in pe_terms.items():
            count = sum(combined_text.count(term) for term in terms)
            term_usage[category] = count

        # Sentiment indicators
        positive_words = ['good', 'great', 'excellent', 'effective', 'works', 'helpful', 'success']
        negative_words = ['bad', 'poor', 'ineffective', "doesn't work", 'waste', 'dangerous']
        cautionary_words = ['careful', 'watch out', 'avoid', 'warning', 'risk', 'injury']

        vocab_analysis = {
            'term_usage_by_category': term_usage,
            'positive_word_count': sum(combined_text.count(w) for w in positive_words),
            'negative_word_count': sum(combined_text.count(w) for w in negative_words),
            'cautionary_word_count': sum(combined_text.count(w) for w in cautionary_words),
            'total_words': len(combined_text.split()),
            'unique_words': len(set(combined_text.split()))
        }

        self.analysis['vocabulary_analysis'] = vocab_analysis

    def analyze_tone(self):
        """Analyze tone and communication style"""
        print(f"\n🎯 Analyzing tone...")

        all_text = []
        all_text.extend([p['title'] + ' ' + (p['body'] or '') for p in self.posts])
        all_text.extend([c['body'] for c in self.comments])

        tone_indicators = {
            'question_marks': sum(text.count('?') for text in all_text),
            'exclamation_marks': sum(text.count('!') for text in all_text),
            'ellipsis': sum(text.count('...') for text in all_text),
            'emojis': sum(sum(1 for c in text if ord(c) > 127) for text in all_text),
            'caps_lock_usage': sum(1 for text in all_text if any(word.isupper() and len(word) > 1 for word in text.split())),
            'personal_pronouns': {
                'first_person': sum(text.lower().count(p) for text in all_text for p in [' i ', ' me ', ' my ', ' mine ']),
                'second_person': sum(text.lower().count(p) for text in all_text for p in [' you ', ' your ', ' yours ']),
                'third_person': sum(text.lower().count(p) for text in all_text for p in [' he ', ' she ', ' they ', ' them '])
            }
        }

        # Analyze formality
        informal_markers = ['lol', 'lmao', 'tbh', 'imo', 'fwiw', 'btw', 'afaik', 'gonna', 'wanna', 'kinda']
        formal_markers = ['therefore', 'however', 'furthermore', 'nevertheless', 'accordingly']

        tone_indicators['informal_marker_count'] = sum(sum(text.lower().count(m) for m in informal_markers) for text in all_text)
        tone_indicators['formal_marker_count'] = sum(sum(text.lower().count(m) for m in formal_markers) for text in all_text)

        self.analysis['tone_indicators'] = tone_indicators

    def extract_content_examples(self):
        """Extract high-quality examples of posts and comments"""
        print(f"\n📋 Extracting content examples...")

        # Top posts by engagement
        top_posts = sorted(self.posts, key=lambda x: x['score'] + x['num_comments'], reverse=True)[:10]
        self.analysis['content_examples']['posts'] = [
            {
                'title': p['title'],
                'body_preview': (p['body'][:500] + '...') if p['body'] and len(p['body']) > 500 else p['body'],
                'subreddit': p['subreddit'],
                'score': p['score'],
                'num_comments': p['num_comments'],
                'engagement': p['score'] + p['num_comments']
            }
            for p in top_posts
        ]

        # Top comments by score
        top_comments = sorted(self.comments, key=lambda x: x['score'], reverse=True)[:20]
        self.analysis['content_examples']['comments'] = [
            {
                'body_preview': (c['body'][:500] + '...') if len(c['body']) > 500 else c['body'],
                'subreddit': c['subreddit'],
                'score': c['score'],
                'parent_post': c['parent_post']['title'] if c['parent_post'] else None,
                'comment_length': len(c['body'])
            }
            for c in top_comments
        ]

    def generate_best_practices(self):
        """Generate best practices based on analysis"""
        print(f"\n✨ Generating best practices...")

        practices = []

        # Post title practices
        if self.posts:
            pp = self.analysis['posting_patterns']
            if pp.get('title_patterns', {}).get('starts_with_question', 0) > 0.5:
                practices.append({
                    'category': 'Post Titles',
                    'practice': 'Start titles with questions to drive engagement',
                    'evidence': f"{pp['title_patterns']['starts_with_question']*100:.1f}% of posts start with questions"
                })

            if pp.get('avg_score', 0) > 20:
                practices.append({
                    'category': 'Post Quality',
                    'practice': f'Average post length: {pp["avg_body_length"]:.0f} characters',
                    'evidence': f"Achieves avg score of {pp['avg_score']:.1f}"
                })

        # Comment structure practices
        if self.comments:
            cp = self.analysis['commenting_patterns']
            struct = cp.get('structure_patterns', {})

            if struct.get('multiline_ratio', 0) > 0.3:
                practices.append({
                    'category': 'Comment Structure',
                    'practice': 'Use paragraph breaks for readability',
                    'evidence': f"{struct['multiline_ratio']*100:.1f}% of comments have multiple paragraphs"
                })

            if struct.get('contains_bullets', 0) > 0.2:
                practices.append({
                    'category': 'Comment Structure',
                    'practice': 'Use bullet points to organize information',
                    'evidence': f"{struct['contains_bullets']*100:.1f}% of comments use bullet lists"
                })

            if cp.get('avg_score', 0) > 5:
                practices.append({
                    'category': 'Comment Quality',
                    'practice': f'Average comment length: {cp["avg_comment_length"]:.0f} characters',
                    'evidence': f"Achieves avg score of {cp['avg_score']:.1f}"
                })

        # Tone practices
        tone = self.analysis['tone_indicators']
        if tone.get('informal_marker_count', 0) > tone.get('formal_marker_count', 0):
            practices.append({
                'category': 'Tone',
                'practice': 'Maintain conversational, informal tone',
                'evidence': f"Informal markers used {tone['informal_marker_count']} times vs formal {tone['formal_marker_count']}"
            })

        # Vocabulary practices
        vocab = self.analysis['vocabulary_analysis']
        term_usage = vocab.get('term_usage_by_category', {})
        top_category = max(term_usage.items(), key=lambda x: x[1]) if term_usage else None
        if top_category:
            practices.append({
                'category': 'Vocabulary',
                'practice': f'Focus on {top_category[0].replace("_", " ")} terminology',
                'evidence': f"{top_category[0]} terms used {top_category[1]} times"
            })

        self.analysis['best_practices'] = practices

    def run_complete_analysis(self, limit=200):
        """Run full analysis pipeline"""
        print(f"\n{'='*60}")
        print(f"Starting analysis for u/{self.username}")
        print(f"{'='*60}")

        self.gather_user_data(limit)
        self.analyze_posting_patterns()
        self.analyze_commenting_patterns()
        self.analyze_vocabulary()
        self.analyze_tone()
        self.extract_content_examples()
        self.generate_best_practices()

        print(f"\n✅ Analysis complete for u/{self.username}")

        return self.analysis


def generate_combined_guidelines(analyses):
    """Generate posting guidelines based on multiple user analyses"""
    print(f"\n{'='*60}")
    print(f"Generating Combined Reddit Posting Guidelines")
    print(f"{'='*60}")

    guidelines = {
        'meta': {
            'generated_at': datetime.now().isoformat(),
            'users_analyzed': [a['username'] for a in analyses],
            'total_posts_analyzed': sum(a.get('posting_patterns', {}).get('total_posts', 0) for a in analyses),
            'total_comments_analyzed': sum(a.get('commenting_patterns', {}).get('total_comments', 0) for a in analyses)
        },
        'posting_guidelines': {
            'title_best_practices': [],
            'body_structure': [],
            'topic_selection': [],
            'engagement_strategies': []
        },
        'commenting_guidelines': {
            'structure': [],
            'tone': [],
            'interaction_approach': [],
            'value_add': []
        },
        'vocabulary_guide': {
            'recommended_terms': {},
            'tone_modifiers': [],
            'formatting_tips': []
        },
        'example_templates': {
            'question_post': [],
            'progress_post': [],
            'helpful_comment': [],
            'beginner_response': []
        },
        'user_specific_insights': {}
    }

    # Analyze each user
    for analysis in analyses:
        username = analysis['username']
        guidelines['user_specific_insights'][username] = {
            'strengths': [],
            'signature_style': [],
            'engagement_metrics': {}
        }

        # Extract strengths
        if analysis.get('posting_patterns'):
            avg_score = analysis['posting_patterns'].get('avg_score', 0)
            if avg_score > 30:
                guidelines['user_specific_insights'][username]['strengths'].append(f"High engagement posts (avg score: {avg_score:.1f})")

        if analysis.get('commenting_patterns'):
            avg_score = analysis['commenting_patterns'].get('avg_score', 0)
            if avg_score > 10:
                guidelines['user_specific_insights'][username]['strengths'].append(f"Valuable comments (avg score: {avg_score:.1f})")

        # Signature style
        tone = analysis.get('tone_indicators', {})
        if tone.get('informal_marker_count', 0) > 10:
            guidelines['user_specific_insights'][username]['signature_style'].append("Conversational, approachable tone")

        struct = analysis.get('commenting_patterns', {}).get('structure_patterns', {})
        if struct.get('contains_bullets', 0) > 0.3:
            guidelines['user_specific_insights'][username]['signature_style'].append("Uses bullet points for clarity")
        if struct.get('multiline_ratio', 0) > 0.4:
            guidelines['user_specific_insights'][username]['signature_style'].append("Well-structured multi-paragraph responses")

    # Aggregate best practices
    all_practices = []
    for analysis in analyses:
        all_practices.extend(analysis.get('best_practices', []))

    # Group by category
    practices_by_category = defaultdict(list)
    for practice in all_practices:
        practices_by_category[practice['category']].append(practice)

    # Add to guidelines
    for category, practices in practices_by_category.items():
        if category == 'Post Titles':
            guidelines['posting_guidelines']['title_best_practices'].extend(practices)
        elif category in ['Post Quality', 'Comment Quality']:
            guidelines['posting_guidelines']['body_structure'].extend(practices)
        elif category == 'Comment Structure':
            guidelines['commenting_guidelines']['structure'].extend(practices)
        elif category == 'Tone':
            guidelines['commenting_guidelines']['tone'].extend(practices)
        elif category == 'Vocabulary':
            guidelines['vocabulary_guide']['recommended_terms'] = practices

    return guidelines


def main():
    """Main execution"""
    print("\n" + "="*60)
    print("Reddit User Style Analysis - Growth PE Marketing")
    print("="*60)

    all_analyses = []

    for username in TARGET_USERS:
        analyzer = UserStyleAnalyzer(username)
        analysis = analyzer.run_complete_analysis(limit=200)
        all_analyses.append(analysis)

        # Save individual analysis
        output_file = f'docs/user_analysis_{username}.json'
        with open(output_file, 'w') as f:
            json.dump(analysis, f, indent=2)
        print(f"\n💾 Saved analysis to {output_file}")

    # Generate combined guidelines
    guidelines = generate_combined_guidelines(all_analyses)

    # Save combined guidelines
    guidelines_file = 'docs/reddit_posting_guidelines.json'
    with open(guidelines_file, 'w') as f:
        json.dump(guidelines, f, indent=2)
    print(f"\n💾 Saved combined guidelines to {guidelines_file}")

    # Generate markdown report
    generate_markdown_report(all_analyses, guidelines)

    print("\n✅ Analysis complete!")
    print(f"📊 Analyzed {len(TARGET_USERS)} users")
    print(f"📝 Generated posting guidelines and best practices")


def generate_markdown_report(analyses, guidelines):
    """Generate human-readable markdown report"""
    report = f"""# Reddit Communication Style Guide - Growth PE Marketing

**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**Users Analyzed:** {', '.join(['u/' + a['username'] for a in analyses])}

---

## Executive Summary

This guide analyzes the communication patterns of successful PE community contributors to develop authentic, engaging content strategies for Growth app marketing on Reddit.

### Users Analyzed

"""

    for analysis in analyses:
        username = analysis['username']
        profile = analysis.get('profile', {})
        report += f"""
#### u/{username}

- **Account Age:** {profile.get('account_age_days', 0)} days
- **Total Karma:** {profile.get('total_karma', 0):,}
- **Link Karma:** {profile.get('link_karma', 0):,}
- **Comment Karma:** {profile.get('comment_karma', 0):,}
- **Posts Analyzed:** {analysis.get('posting_patterns', {}).get('total_posts', 0)}
- **Comments Analyzed:** {analysis.get('commenting_patterns', {}).get('total_comments', 0)}

"""

    report += """
---

## Part 1: Posting Guidelines

### Title Best Practices

"""

    for analysis in analyses:
        pp = analysis.get('posting_patterns', {})
        if pp:
            report += f"""
**u/{analysis['username']} Style:**
- Average title length: {pp.get('avg_title_length', 0):.0f} characters
- Question-based: {pp.get('title_patterns', {}).get('starts_with_question', 0)*100:.0f}%
- Average engagement: {pp.get('avg_score', 0):.1f} upvotes, {pp.get('avg_comments', 0):.1f} comments

"""

    report += """
### Body Structure & Content

"""

    for analysis in analyses:
        pp = analysis.get('posting_patterns', {})
        if pp:
            report += f"""
**u/{analysis['username']} Approach:**
- Average body length: {pp.get('avg_body_length', 0):.0f} characters
- Self-post ratio: {pp.get('self_post_ratio', 0)*100:.0f}%
- Most active in: {', '.join(list(pp.get('subreddit_distribution', {}).keys())[:3])}

"""

    report += """
---

## Part 2: Commenting Guidelines

### Comment Structure

"""

    for analysis in analyses:
        cp = analysis.get('commenting_patterns', {})
        struct = cp.get('structure_patterns', {})
        if cp:
            report += f"""
**u/{analysis['username']} Pattern:**
- Average length: {cp.get('avg_comment_length', 0):.0f} characters
- Multi-paragraph: {struct.get('multiline_ratio', 0)*100:.0f}%
- Uses bullets: {struct.get('contains_bullets', 0)*100:.0f}%
- Uses numbered lists: {struct.get('contains_numbered_list', 0)*100:.0f}%
- Includes quotes: {struct.get('contains_quotes', 0)*100:.0f}%
- Uses bold/emphasis: {struct.get('contains_bold', 0)*100:.0f}%

"""

    report += """
### Tone & Voice

"""

    for analysis in analyses:
        tone = analysis.get('tone_indicators', {})
        if tone:
            informal = tone.get('informal_marker_count', 0)
            formal = tone.get('formal_marker_count', 0)
            style = "Conversational/Informal" if informal > formal else "Formal/Technical"

            report += f"""
**u/{analysis['username']} Tone:**
- Style: {style}
- Question marks: {tone.get('question_marks', 0)}
- Exclamation marks: {tone.get('exclamation_marks', 0)}
- Personal pronouns (1st person): {tone.get('personal_pronouns', {}).get('first_person', 0)}
- Personal pronouns (2nd person): {tone.get('personal_pronouns', {}).get('second_person', 0)}

"""

    report += """
---

## Part 3: Vocabulary & Terminology

### PE Term Usage Patterns

"""

    for analysis in analyses:
        vocab = analysis.get('vocabulary_analysis', {})
        term_usage = vocab.get('term_usage_by_category', {})
        if term_usage:
            report += f"""
**u/{analysis['username']} Focus Areas:**
"""
            sorted_terms = sorted(term_usage.items(), key=lambda x: x[1], reverse=True)
            for category, count in sorted_terms[:5]:
                report += f"- {category.replace('_', ' ').title()}: {count} mentions\n"
            report += "\n"

    report += """
---

## Part 4: Best Practices Summary

"""

    practices_by_category = defaultdict(list)
    for analysis in analyses:
        for practice in analysis.get('best_practices', []):
            practices_by_category[practice['category']].append({
                'user': analysis['username'],
                'practice': practice['practice'],
                'evidence': practice['evidence']
            })

    for category, practices in practices_by_category.items():
        report += f"""
### {category}

"""
        for p in practices:
            report += f"- **u/{p['user']}:** {p['practice']}\n"
            report += f"  - *{p['evidence']}*\n"
        report += "\n"

    report += """
---

## Part 5: Content Examples

### High-Engagement Posts

"""

    for analysis in analyses:
        examples = analysis.get('content_examples', {}).get('posts', [])
        if examples:
            report += f"""
#### u/{analysis['username']} Top Posts

"""
            for i, example in enumerate(examples[:5], 1):
                report += f"""
**{i}. {example['title']}**
- Subreddit: r/{example['subreddit']}
- Engagement: {example['score']} upvotes, {example['num_comments']} comments
"""
                if example.get('body_preview'):
                    report += f"- Preview: {example['body_preview'][:200]}...\n"
                report += "\n"

    report += """
### High-Value Comments

"""

    for analysis in analyses:
        examples = analysis.get('content_examples', {}).get('comments', [])
        if examples:
            report += f"""
#### u/{analysis['username']} Top Comments

"""
            for i, example in enumerate(examples[:5], 1):
                report += f"""
**{i}. Comment** (Score: {example['score']})
- Subreddit: r/{example['subreddit']}
- Length: {example['comment_length']} chars
"""
                if example.get('parent_post'):
                    report += f"- On: {example['parent_post']}\n"
                report += f"- Preview: {example['body_preview'][:200]}...\n\n"

    report += """
---

## Part 6: Implementation Guidelines for Growth Marketing

### When to Post

1. **Question Posts** - When seeking community input or validating features
2. **Progress Posts** - When sharing Growth app development milestones
3. **Educational Posts** - When contributing PE training knowledge
4. **Discussion Posts** - When exploring community needs/pain points

### When to Comment

1. **Beginner Questions** - Offer Growth app as a solution
2. **Routine Planning Discussions** - Highlight Growth's routine features
3. **Progress Tracking Threads** - Mention Growth's measurement tools
4. **Safety Concerns** - Position Growth as safety-first approach

### Authentic Marketing Approach

1. **Lead with Value** - Answer the question first, mention Growth second
2. **Be Transparent** - Identify affiliation with Growth when relevant
3. **Community First** - Contribute genuinely, not just to promote
4. **Respect Rules** - Follow each subreddit's self-promotion guidelines

---

**Note:** This analysis is based on public Reddit data and is intended for educational and strategic planning purposes.
"""

    # Save markdown report
    report_file = 'docs/REDDIT_STYLE_GUIDE.md'
    with open(report_file, 'w') as f:
        f.write(report)
    print(f"\n📄 Generated markdown report: {report_file}")


if __name__ == '__main__':
    main()
