#!/usr/bin/env python3
"""
Scrape Educational Content from PE Subreddits for Article Creation
"""

import json
import praw
import os
import re
from datetime import datetime
from pathlib import Path
from dotenv import load_dotenv
from collections import defaultdict

# Load environment variables
load_dotenv('.env')

# Reddit configuration
reddit = praw.Reddit(
    client_id=os.getenv('REDDIT_CLIENT_ID'),
    client_secret=os.getenv('REDDIT_CLIENT_SECRET'),
    user_agent='GrowthLabs_Education_Scraper/1.0'
)

# Article topics to research
ARTICLE_TOPICS = [
    {
        'id': 'science_of_tissue_expansion',
        'title': 'The Science of Tissue Expansion',
        'keywords': ['tissue expansion', 'tunica', 'smooth muscle', 'collagen', 'elastin', 'mechanotransduction', 'cellular']
    },
    {
        'id': 'understanding_eq_blood_flow',
        'title': 'Understanding EQ and Blood Flow',
        'keywords': ['EQ', 'erection quality', 'blood flow', 'nitric oxide', 'endothelial', 'vascular', 'cardiovascular']
    },
    {
        'id': 'injury_prevention_recovery',
        'title': 'Injury Prevention and Recovery',
        'keywords': ['injury', 'recovery', 'healing', 'thrombosis', 'nerve damage', 'symptoms', 'prevention', 'rest']
    },
    {
        'id': 'beginner_fundamentals',
        'title': 'PE Fundamentals for Beginners',
        'keywords': ['beginner', 'newbie', 'starting', 'basics', 'fundamentals', 'first', 'routine', 'conditioning']
    },
    {
        'id': 'heat_application_benefits',
        'title': 'Heat Application and Its Benefits',
        'keywords': ['heat', 'warm up', 'temperature', 'IR lamp', 'heating pad', 'hot wrap', 'rice sock']
    },
    {
        'id': 'measuring_tracking_progress',
        'title': 'Measuring and Tracking Progress',
        'keywords': ['measuring', 'measurement', 'BPEL', 'NBPEL', 'girth', 'tracking', 'progress', 'gains', 'photos']
    },
    {
        'id': 'supplements_nutrition',
        'title': 'Supplements and Nutrition for PE',
        'keywords': ['supplements', 'L-citrulline', 'L-arginine', 'zinc', 'vitamin', 'nutrition', 'diet', 'hydration']
    },
    {
        'id': 'rest_recovery_decon',
        'title': 'Rest Days and Deconditioning',
        'keywords': ['rest', 'recovery', 'decon', 'deconditioning', 'break', 'plateau', 'overtraining', 'fatigue']
    }
]

def scrape_educational_content():
    """Scrape educational content from PE subreddits"""

    print("🔍 Scraping educational content from PE subreddits...")

    subreddits = ['thescienceofpe', 'gettingbigger', 'ajelqforyou']
    educational_data = defaultdict(lambda: {
        'posts': [],
        'wiki_content': [],
        'scientific_mentions': [],
        'key_points': set(),
        'warnings': set(),
        'citations': []
    })

    for sub_name in subreddits:
        print(f"\n📚 Processing r/{sub_name}")

        try:
            subreddit = reddit.subreddit(sub_name)

            # Search for educational content by topic
            for topic in ARTICLE_TOPICS:
                print(f"  🔎 Researching: {topic['title']}")

                for keyword in topic['keywords'][:3]:  # Limit searches
                    try:
                        for post in subreddit.search(keyword, limit=5, sort='top'):
                            if post.score > 10:
                                # Extract educational content
                                post_data = {
                                    'title': post.title,
                                    'content': post.selftext[:2000] if post.selftext else '',
                                    'score': post.score,
                                    'url': post.url,
                                    'subreddit': sub_name
                                }

                                educational_data[topic['id']]['posts'].append(post_data)

                                # Extract key points and citations
                                extract_educational_info(post.selftext, educational_data[topic['id']])

                                # Check top comments for additional info
                                post.comments.replace_more(limit=0)
                                for comment in post.comments.list()[:3]:
                                    if comment.score > 5:
                                        extract_educational_info(comment.body, educational_data[topic['id']])

                    except Exception as e:
                        print(f"    ⚠️ Error searching '{keyword}': {e}")
                        continue

            # Try to get wiki content
            try:
                for wiki_page in ['index', 'faq', 'glossary', 'science']:
                    try:
                        wiki = subreddit.wiki[wiki_page]
                        content = wiki.content_md

                        # Match content to topics
                        for topic in ARTICLE_TOPICS:
                            for keyword in topic['keywords']:
                                if keyword.lower() in content.lower():
                                    educational_data[topic['id']]['wiki_content'].append({
                                        'source': f"r/{sub_name}/wiki/{wiki_page}",
                                        'excerpt': extract_relevant_section(content, keyword)
                                    })
                                    break
                    except:
                        continue
            except:
                pass

        except Exception as e:
            print(f"  ❌ Error with r/{sub_name}: {e}")
            continue

    return educational_data

def extract_educational_info(text, data_dict):
    """Extract educational information from text"""
    if not text:
        return

    text_lower = text.lower()

    # Look for scientific terms and studies
    scientific_patterns = [
        r'study\s+(?:showed|found|demonstrated)',
        r'research\s+(?:indicates|suggests|shows)',
        r'scientifically\s+proven',
        r'\d+%\s+(?:increase|improvement|gain)',
        r'mechanism',
        r'physiolog',
        r'biomechanic'
    ]

    for pattern in scientific_patterns:
        if re.search(pattern, text_lower):
            # Extract the sentence
            sentences = text.split('.')
            for sentence in sentences:
                if re.search(pattern, sentence.lower()):
                    data_dict['scientific_mentions'].append(sentence.strip())
                    break

    # Extract key points (numbered lists or bullet points)
    lines = text.split('\n')
    for line in lines:
        line = line.strip()
        if line and (line[0].isdigit() or line.startswith('•') or line.startswith('*') or line.startswith('-')):
            cleaned = re.sub(r'^[\d\.\-\*\•\s]+', '', line).strip()
            if len(cleaned) > 20:
                data_dict['key_points'].add(cleaned)

    # Extract warnings
    warning_keywords = ['warning', 'caution', 'danger', 'never', 'avoid', 'risk', 'injury', 'important']
    for keyword in warning_keywords:
        if keyword in text_lower:
            sentences = text.split('.')
            for sentence in sentences:
                if keyword in sentence.lower() and len(sentence) > 20:
                    data_dict['warnings'].add(sentence.strip())

    # Look for citations (URLs to studies or papers)
    urls = re.findall(r'https?://(?:www\.)?(?:ncbi|pubmed|doi|sciencedirect|springer|nature)[^\s\)]+', text)
    for url in urls:
        data_dict['citations'].append(url)

def extract_relevant_section(content, keyword, context_lines=5):
    """Extract relevant section around a keyword"""
    lines = content.split('\n')
    relevant_lines = []

    for i, line in enumerate(lines):
        if keyword.lower() in line.lower():
            # Get context before and after
            start = max(0, i - context_lines)
            end = min(len(lines), i + context_lines + 1)
            relevant_lines.extend(lines[start:end])

    return '\n'.join(relevant_lines[:1000])  # Limit length

def save_educational_data(educational_data):
    """Save scraped educational data"""
    output_dir = Path('extracted_data')
    output_dir.mkdir(exist_ok=True)

    # Save raw data
    output_file = output_dir / 'educational_content_raw.json'

    # Convert sets to lists for JSON serialization
    serializable_data = {}
    for topic_id, data in educational_data.items():
        serializable_data[topic_id] = {
            'posts': data['posts'],
            'wiki_content': data['wiki_content'],
            'scientific_mentions': list(data['scientific_mentions'])[:20],
            'key_points': list(data['key_points'])[:30],
            'warnings': list(data['warnings'])[:10],
            'citations': list(set(data['citations']))[:10]
        }

    with open(output_file, 'w') as f:
        json.dump(serializable_data, f, indent=2)

    print(f"\n✅ Educational data saved to {output_file}")

    # Print summary
    print("\n📊 Content Summary:")
    for topic_id, data in educational_data.items():
        topic = next(t for t in ARTICLE_TOPICS if t['id'] == topic_id)
        print(f"\n{topic['title']}:")
        print(f"  Posts collected: {len(data['posts'])}")
        print(f"  Wiki sections: {len(data['wiki_content'])}")
        print(f"  Key points: {len(data['key_points'])}")
        print(f"  Scientific mentions: {len(data['scientific_mentions'])}")
        print(f"  Warnings: {len(data['warnings'])}")
        print(f"  Citations: {len(data['citations'])}")

    return serializable_data

# Main execution
if __name__ == "__main__":
    print("=" * 60)
    print("Educational Content Scraper for PE Articles")
    print("=" * 60)

    # Scrape content
    educational_data = scrape_educational_content()

    # Save data
    saved_data = save_educational_data(educational_data)

    print("\n✅ Educational content collection complete!")
    print("Ready to create comprehensive articles with citations!")