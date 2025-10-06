#!/usr/bin/env python3
"""
Article Generation Script for Story 7.2
Generates 8 educational articles from scraped Reddit data with scientific citations.
"""

import json
import os
import sys
from typing import Dict, List, Any

# Article configuration based on Story 7.2 Dev Notes
ARTICLE_CONFIG = {
    "science_of_tissue_expansion": {
        "title": "The Science of Tissue Expansion in PE Training",
        "category": "Science",
        "expected_urls": 12,
        "expected_size": "3.9KB"
    },
    "understanding_eq_blood_flow": {
        "title": "Understanding Erection Quality and Blood Flow",
        "category": "Science",
        "expected_urls": 35,
        "expected_size": "13.9KB"
    },
    "injury_prevention_recovery": {
        "title": "Injury Prevention and Recovery in PE Training",
        "category": "Safety",
        "expected_urls": 10,
        "expected_size": "5.6KB"
    },
    "beginner_fundamentals": {
        "title": "PE Fundamentals for Beginners",
        "category": "Basics",
        "expected_urls": 34,
        "expected_size": "6.5KB"
    },
    "heat_application_benefits": {
        "title": "Heat Application and Its Benefits in PE",
        "category": "Technique",
        "expected_urls": 11,
        "expected_size": "2.5KB"
    },
    "measuring_tracking_progress": {
        "title": "Measuring and Tracking PE Progress",
        "category": "Progression",
        "expected_urls": 24,
        "expected_size": "17.8KB"
    },
    "supplements_nutrition": {
        "title": "Supplements and Nutrition for PE",
        "category": "Science",
        "expected_urls": 6,
        "expected_size": "2.1KB"
    },
    "rest_recovery_decon": {
        "title": "Rest Days and Deconditioning Prevention",
        "category": "Progression",
        "expected_urls": 10,
        "expected_size": "13.2KB"
    }
}

# Standard medical disclaimer from Story 7.2
MEDICAL_DISCLAIMER = """Always consult with a healthcare provider before starting any PE training program. This content is for educational purposes only and does not constitute medical advice. PE training carries risks including but not limited to tissue damage, nerve injury, and vascular complications. Stop immediately and seek medical attention if you experience pain, numbness, discoloration, or any unusual symptoms."""

# Article structure template from Story 7.2
ARTICLE_TEMPLATE = """# {title}

## Overview
{overview}

## Key Concepts
{key_concepts}

## Scientific Evidence
{scientific_evidence}

## Safety Considerations
{safety_considerations}

## Practical Application
{practical_application}

## Medical Disclaimer
{medical_disclaimer}

## References
{references}
"""


def load_scraped_data(input_file: str) -> Dict[str, Any]:
    """Load the scraped Reddit data from Story 7.1."""
    print(f"Loading scraped data from: {input_file}")

    if not os.path.exists(input_file):
        print(f"ERROR: Input file not found: {input_file}")
        sys.exit(1)

    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    print(f"✓ Loaded data for {len(data)} topics")
    return data


def extract_reddit_urls(wiki_content: List[Dict]) -> List[str]:
    """Extract Reddit URLs from wiki content."""
    urls = []
    for section in wiki_content:
        excerpt = section.get('excerpt', '')
        # Extract URLs from markdown links [text](url)
        import re
        url_pattern = r'https://(?:www\.)?reddit\.com/[^\s\)]+(?=\)|$)'
        found_urls = re.findall(url_pattern, excerpt)
        urls.extend(found_urls)

    return list(set(urls))  # Remove duplicates


def generate_article_content(topic_key: str, topic_data: Dict, config: Dict) -> str:
    """
    Generate article content from topic data.
    This is a placeholder - actual implementation would use Claude API.
    """

    # Extract Reddit URLs
    reddit_urls = extract_reddit_urls(topic_data.get('wiki_content', []))

    print(f"\n{'='*60}")
    print(f"Topic: {config['title']}")
    print(f"Category: {config['category']}")
    print(f"Reddit URLs found: {len(reddit_urls)}")
    print(f"{'='*60}")

    # Placeholder content structure
    overview = f"""This article provides a comprehensive guide to {config['title'].lower()}.
Based on community research and discussions from r/TheScienceOfPE and related communities,
we synthesize key findings and best practices."""

    key_concepts = f"""### Core Principles
Content synthesized from {len(reddit_urls)} community discussions and research threads."""

    scientific_evidence = """### Research Findings
Scientific citations would be extracted and formatted here in APA 7th edition."""

    safety_considerations = """### Safety First
Always prioritize safety and listen to your body. Stop immediately if you experience pain,
numbness, or discoloration."""

    practical_application = """### How to Apply
Practical guidance would be synthesized here from community best practices."""

    # Generate article using template
    article = ARTICLE_TEMPLATE.format(
        title=config['title'],
        overview=overview,
        key_concepts=key_concepts,
        scientific_evidence=scientific_evidence,
        safety_considerations=safety_considerations,
        practical_application=practical_application,
        medical_disclaimer=MEDICAL_DISCLAIMER,
        references="[Citations would be listed here in APA 7th edition format]"
    )

    return article


def create_citations_placeholder(reddit_urls: List[str]) -> List[Dict]:
    """Create placeholder citation objects from Reddit URLs."""
    citations = []

    # Take first 3-5 URLs as citation sources
    for i, url in enumerate(reddit_urls[:5], 1):
        citation = {
            "id": f"citation{i}",
            "authors": "Reddit Community",
            "year": "2024",
            "title": f"PE Research Discussion {i}",
            "journal": "r/TheScienceOfPE",
            "volume": "",
            "pages": "",
            "doi": "",
            "url": url
        }
        citations.append(citation)

    return citations


def generate_article_json(topic_key: str, topic_data: Dict, config: Dict,
                          article_content: str, reddit_urls: List[str]) -> Dict:
    """Generate Firestore-compatible JSON structure for article."""

    citations = create_citations_placeholder(reddit_urls)

    article_json = {
        "title": config['title'],
        "content_text": article_content,
        "category": config['category'],
        "citations": citations,
        "medical_disclaimer": MEDICAL_DISCLAIMER,
        "local_image_name": topic_key
    }

    return article_json


def save_article_json(article_json: Dict, output_path: str):
    """Save article JSON to file."""
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(article_json, f, indent=2, ensure_ascii=False)

    print(f"✓ Saved article to: {output_path}")


def generate_all_articles(input_file: str, output_dir: str):
    """Main function to generate all 8 articles."""

    print("\n" + "="*60)
    print("Article Generation Script - Story 7.2")
    print("="*60 + "\n")

    # Load scraped data
    scraped_data = load_scraped_data(input_file)

    # Generate each article
    total_citations = 0
    articles_generated = 0

    for topic_key, config in ARTICLE_CONFIG.items():
        print(f"\nProcessing: {topic_key}")

        # Get topic data
        topic_data = scraped_data.get(topic_key, {})

        if not topic_data:
            print(f"  ⚠ WARNING: No data found for {topic_key}")
            continue

        # Extract Reddit URLs
        reddit_urls = extract_reddit_urls(topic_data.get('wiki_content', []))

        # Generate article content
        article_content = generate_article_content(topic_key, topic_data, config)

        # Generate JSON structure
        article_json = generate_article_json(
            topic_key, topic_data, config, article_content, reddit_urls
        )

        # Save to file
        output_path = os.path.join(output_dir, f"{topic_key}.json")
        save_article_json(article_json, output_path)

        articles_generated += 1
        total_citations += len(article_json['citations'])

        print(f"  ✓ Article generated: {config['title']}")
        print(f"  ✓ Citations: {len(article_json['citations'])}")
        print(f"  ✓ Category: {config['category']}")

    # Generate summary
    print("\n" + "="*60)
    print("GENERATION SUMMARY")
    print("="*60)
    print(f"Articles generated: {articles_generated}/8")
    print(f"Total citations: {total_citations}")
    print(f"Output directory: {output_dir}")
    print("="*60 + "\n")

    return articles_generated, total_citations


def main():
    """Entry point for article generation script."""

    # Paths from Story 7.2
    script_dir = os.path.dirname(os.path.abspath(__file__))
    input_file = os.path.join(script_dir, 'extracted_data', 'educational_content_raw.json')
    output_dir = os.path.join(script_dir, 'generated_articles')

    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Generate articles
    try:
        articles_generated, total_citations = generate_all_articles(input_file, output_dir)

        print(f"\n✓ SUCCESS: Generated {articles_generated} articles with {total_citations} citations")
        print(f"\nNext steps:")
        print(f"1. Review generated articles in: {output_dir}")
        print(f"2. Verify citation URLs are accessible")
        print(f"3. Enhance article content with Claude AI (if needed)")
        print(f"4. Run Story 7.2 manual verification checklist")

        return 0

    except Exception as e:
        print(f"\n✗ ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
