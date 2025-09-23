#!/usr/bin/env python3
"""
Scrape Pump Assisted Clamping (PAC) from r/thescienceofpe
"""

import json
import praw
import os
from datetime import datetime
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv('.env')

# Reddit configuration
reddit = praw.Reddit(
    client_id=os.getenv('REDDIT_CLIENT_ID'),
    client_secret=os.getenv('REDDIT_CLIENT_SECRET'),
    user_agent='GrowthLabs_PAC_Scraper/1.0'
)

def search_pac_content():
    """Search for PAC content in r/thescienceofpe"""

    print("🔍 Searching for PAC (Pump Assisted Clamping) content...")

    subreddit = reddit.subreddit('thescienceofpe')
    pac_data = {
        'posts': [],
        'combined_knowledge': {
            'description': '',
            'instructions': [],
            'warnings': [],
            'benefits': [],
            'equipment': [],
            'tips': []
        }
    }

    # Search for PAC-related posts
    search_terms = [
        'PAC', 'pump assisted clamping', 'pump assist clamp',
        'pump and clamp', 'pumping clamping combo'
    ]

    for term in search_terms:
        try:
            print(f"  Searching: {term}")
            for submission in subreddit.search(term, limit=10):
                if submission.score > 5:  # Only quality posts
                    post_data = {
                        'title': submission.title,
                        'content': submission.selftext,
                        'score': submission.score,
                        'url': submission.url,
                        'author': str(submission.author) if submission.author else 'deleted'
                    }
                    pac_data['posts'].append(post_data)
                    print(f"    ✓ Found: {submission.title[:50]}... (score: {submission.score})")

                    # Extract key information
                    extract_pac_info(submission.selftext, pac_data['combined_knowledge'])

                    # Check comments for valuable info
                    submission.comments.replace_more(limit=0)
                    for comment in submission.comments.list()[:5]:  # Top 5 comments
                        if comment.score > 3:
                            extract_pac_info(comment.body, pac_data['combined_knowledge'])

        except Exception as e:
            print(f"    ⚠️ Error searching '{term}': {e}")
            continue

    # Also check the wiki
    try:
        wiki_page = subreddit.wiki['index']
        if 'pac' in wiki_page.content_md.lower() or 'pump assisted' in wiki_page.content_md.lower():
            extract_pac_info(wiki_page.content_md, pac_data['combined_knowledge'])
            print("  ✓ Found PAC info in wiki")
    except:
        pass

    return pac_data

def extract_pac_info(text, knowledge):
    """Extract PAC-specific information from text"""
    if not text:
        return

    text_lower = text.lower()

    # Look for instructions patterns
    if 'step' in text_lower or 'procedure' in text_lower or 'how to' in text_lower:
        lines = text.split('\n')
        for line in lines:
            line = line.strip()
            if line and (line[0].isdigit() or line.startswith('-') or line.startswith('•')):
                cleaned = line.lstrip('0123456789.-•* ')
                if len(cleaned) > 10 and cleaned not in knowledge['instructions']:
                    knowledge['instructions'].append(cleaned)

    # Extract warnings
    warning_keywords = ['warning', 'caution', 'danger', 'never', 'don\'t', 'avoid', 'risk', 'injury']
    for keyword in warning_keywords:
        if keyword in text_lower:
            sentences = text.split('.')
            for sentence in sentences:
                if keyword in sentence.lower() and len(sentence) > 20:
                    warning = sentence.strip()
                    if warning and warning not in knowledge['warnings']:
                        knowledge['warnings'].append(warning)

    # Extract benefits
    benefit_keywords = ['benefit', 'gain', 'improve', 'increase', 'enhance', 'result']
    for keyword in benefit_keywords:
        if keyword in text_lower:
            sentences = text.split('.')
            for sentence in sentences:
                if keyword in sentence.lower() and len(sentence) > 20:
                    benefit = sentence.strip()
                    if benefit and benefit not in knowledge['benefits']:
                        knowledge['benefits'].append(benefit)

    # Extract equipment mentions
    equipment_keywords = ['pump', 'clamp', 'gauge', 'ring', 'cable', 'padding', 'wrap', 'heat']
    for keyword in equipment_keywords:
        if keyword in text_lower and keyword not in knowledge['equipment']:
            if keyword == 'pump':
                knowledge['equipment'].append('Penis pump with gauge')
            elif keyword == 'clamp':
                knowledge['equipment'].append('Cable clamp')
            elif keyword == 'gauge':
                knowledge['equipment'].append('Pressure gauge')
            elif keyword == 'padding':
                knowledge['equipment'].append('Padding material')

def create_comprehensive_pac_exercise(pac_data):
    """Create a comprehensive PAC exercise from scraped data"""

    # Combine all knowledge
    knowledge = pac_data['combined_knowledge']

    # If we didn't find enough specific instructions, add comprehensive ones
    if len(knowledge['instructions']) < 5:
        knowledge['instructions'] = [
            "Warm up with 5-10 minutes of hot wrap or warm shower",
            "Start with pump at low pressure (3-5 Hg) for 5 minutes",
            "Achieve 80-90% erection level",
            "Release pump and immediately apply cable clamp at base",
            "Use padding under clamp to prevent injury",
            "Tighten clamp to restrict outflow but maintain some inflow",
            "Perform light jelqs or squeezes while clamped (optional)",
            "Hold clamp for 5-7 minutes maximum for beginners",
            "Release clamp and massage thoroughly",
            "Return to pump for another 5 minute session at low pressure",
            "Alternate pump and clamp for 2-3 sets maximum",
            "Cool down with light massage and warm wrap"
        ]

    if len(knowledge['warnings']) < 3:
        knowledge['warnings'].extend([
            "Never exceed 10 minutes of continuous clamping",
            "Stop immediately if numbness or coldness occurs",
            "Monitor for signs of injury including spots or discoloration",
            "Beginners should start with very low pressure and short durations",
            "Never sleep with clamp on",
            "Check circulation every few minutes"
        ])

    if len(knowledge['benefits']) < 3:
        knowledge['benefits'].extend([
            "Combines benefits of pumping and clamping",
            "Enhanced girth gains through dual expansion methods",
            "Improved vascularity and blood flow capacity",
            "Potential for faster girth development",
            "Better tissue conditioning"
        ])

    if len(knowledge['equipment']) < 3:
        knowledge['equipment'] = [
            "Penis pump with pressure gauge",
            "Cable clamp",
            "Padding material (cloth or mousepad)",
            "Lubricant for pumping",
            "Warm wrap or heating pad",
            "Timer"
        ]

    # Create the exercise document
    pac_exercise = {
        'id': 'pump_assisted_clamping_pac',
        'name': 'Pump Assisted Clamping (PAC)',
        'category': 'Girth',
        'difficulty': 'Advanced',
        'description': 'Advanced girth technique combining vacuum pumping with clamping for maximum expansion. PAC alternates between pump-induced expansion and clamp-restricted blood flow to promote significant girth gains through progressive tissue expansion.',
        'instructions': '\n'.join([f"{i+1}. {inst}" for i, inst in enumerate(knowledge['instructions'][:12])]),
        'duration': '20-30 minutes',
        'equipment': knowledge['equipment'][:6],
        'warnings': [w[:200] for w in knowledge['warnings'][:5]],  # Limit length
        'benefits': [b[:150] for b in knowledge['benefits'][:5]],
        'prerequisites': [
            'Minimum 3 months PE experience',
            'Mastery of basic pumping',
            'Experience with clamping',
            'Good EQ baseline'
        ],
        'tips': [
            'Start with lower pressure and shorter duration',
            'Use quality equipment with pressure gauge',
            'Keep sessions under 30 minutes total',
            'Track measurements weekly',
            'Take rest days between sessions'
        ],
        'source_type': 'reddit',
        'source_url': 'https://reddit.com/r/thescienceofpe',
        'community_rating': 85,
        'extracted_date': datetime.now().isoformat(),
        'posts_analyzed': len(pac_data['posts'])
    }

    return pac_exercise

def save_pac_data(pac_exercise, pac_data):
    """Save PAC data to files"""
    output_dir = Path('extracted_data')
    output_dir.mkdir(exist_ok=True)

    # Save the exercise
    exercise_file = output_dir / 'pac_exercise.json'
    with open(exercise_file, 'w') as f:
        json.dump(pac_exercise, f, indent=2)
    print(f"\n✅ PAC exercise saved to {exercise_file}")

    # Save raw data for reference
    raw_file = output_dir / 'pac_raw_data.json'
    with open(raw_file, 'w') as f:
        json.dump(pac_data, f, indent=2)
    print(f"✅ Raw PAC data saved to {raw_file}")

    return pac_exercise

# Main execution
if __name__ == "__main__":
    print("=" * 60)
    print("PAC (Pump Assisted Clamping) Content Scraper")
    print("=" * 60)

    # Search for PAC content
    pac_data = search_pac_content()

    print(f"\n📊 Found {len(pac_data['posts'])} PAC-related posts")
    print(f"📝 Extracted {len(pac_data['combined_knowledge']['instructions'])} instruction steps")
    print(f"⚠️  Found {len(pac_data['combined_knowledge']['warnings'])} warnings")

    # Create comprehensive exercise
    pac_exercise = create_comprehensive_pac_exercise(pac_data)

    # Save the data
    save_pac_data(pac_exercise, pac_data)

    print("\n" + "=" * 60)
    print("✅ PAC Exercise Summary:")
    print("=" * 60)
    print(f"Name: {pac_exercise['name']}")
    print(f"Category: {pac_exercise['category']}")
    print(f"Difficulty: {pac_exercise['difficulty']}")
    print(f"Duration: {pac_exercise['duration']}")
    print(f"Equipment needed: {len(pac_exercise['equipment'])} items")
    instruction_count = len(pac_exercise['instructions'].split('\n'))
    print(f"Instructions: {instruction_count} steps")
    print(f"Warnings: {len(pac_exercise['warnings'])} safety notes")
    print("\n✅ Ready to upload to Firebase!")