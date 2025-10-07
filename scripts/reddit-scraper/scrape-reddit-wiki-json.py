#!/usr/bin/env python3
"""
Reddit Wiki JSON Scraper
Uses Reddit's JSON endpoint to extract wiki content
"""

import json
import requests
import re
from datetime import datetime
from typing import Dict, List, Any
import time

class RedditWikiJSONScraper:
    def __init__(self):
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }
        self.session = requests.Session()
        self.session.headers.update(self.headers)

    def fetch_wiki_json(self, subreddit: str, wiki_page: str = "index") -> Dict[str, Any]:
        """
        Fetch wiki page content using Reddit's JSON endpoint
        """
        # Construct URL - Reddit allows .json suffix for API access
        url = f"https://www.reddit.com/r/{subreddit}/wiki/{wiki_page}.json"

        print(f"Fetching: {url}")

        try:
            response = self.session.get(url)
            response.raise_for_status()

            data = response.json()

            if 'data' in data and 'content_md' in data['data']:
                return {
                    'success': True,
                    'content': data['data']['content_md'],
                    'revision_date': data['data'].get('revision_date'),
                    'revision_by': data['data'].get('revision_by', {}).get('username', 'Unknown')
                }
            else:
                return {
                    'success': False,
                    'error': 'Invalid response structure'
                }

        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 403:
                return {'success': False, 'error': 'Wiki is private or requires authentication'}
            elif e.response.status_code == 404:
                return {'success': False, 'error': 'Wiki page not found'}
            else:
                return {'success': False, 'error': f'HTTP Error: {e}'}

        except Exception as e:
            return {'success': False, 'error': f'Error: {e}'}

    def parse_markdown_for_links(self, markdown_content: str) -> Dict[str, Any]:
        """
        Parse markdown content to extract all links and structure
        """
        knowledge_base = {
            'source': 'r/TheScienceOfPE Wiki',
            'scraped_at': datetime.now().isoformat(),
            'sections': [],
            'all_links': [],
            'categories': {}
        }

        # Extract all markdown links [text](url)
        link_pattern = r'\[([^\]]+)\]\(([^\)]+)\)'
        all_links = re.findall(link_pattern, markdown_content)

        # Process sections based on headers
        lines = markdown_content.split('\n')
        current_section = None
        current_subsection = None

        for line in lines:
            # Check for headers
            if line.startswith('# '):
                current_section = line.replace('# ', '').strip()
                knowledge_base['categories'][current_section] = {'links': [], 'subsections': {}}
                current_subsection = None

            elif line.startswith('## '):
                current_subsection = line.replace('## ', '').strip()
                if current_section:
                    knowledge_base['categories'][current_section]['subsections'][current_subsection] = []

            elif line.startswith('### '):
                sub_sub_section = line.replace('### ', '').strip()
                if current_section and current_subsection:
                    knowledge_base['categories'][current_section]['subsections'][current_subsection].append({
                        'title': sub_sub_section,
                        'links': []
                    })

            # Extract links from this line
            links_in_line = re.findall(link_pattern, line)
            for link_text, link_url in links_in_line:
                link_data = {
                    'text': link_text.strip(),
                    'url': link_url.strip(),
                    'section': current_section,
                    'subsection': current_subsection,
                    'is_reddit': 'reddit.com' in link_url or link_url.startswith('/r/'),
                    'is_external': not ('reddit.com' in link_url or link_url.startswith('/'))
                }

                # Add to all links
                knowledge_base['all_links'].append(link_data)

                # Add to appropriate section
                if current_section:
                    if current_subsection:
                        if isinstance(knowledge_base['categories'][current_section]['subsections'][current_subsection], list):
                            if knowledge_base['categories'][current_section]['subsections'][current_subsection]:
                                knowledge_base['categories'][current_section]['subsections'][current_subsection][-1]['links'].append(link_data)
                        else:
                            knowledge_base['categories'][current_section]['subsections'][current_subsection] = [link_data]
                    else:
                        knowledge_base['categories'][current_section]['links'].append(link_data)

        # Extract reddit user mentions u/username
        user_pattern = r'u/([A-Za-z0-9_-]+)'
        users = re.findall(user_pattern, markdown_content)
        knowledge_base['mentioned_users'] = list(set(users))

        # Extract subreddit mentions r/subreddit
        subreddit_pattern = r'r/([A-Za-z0-9_]+)'
        subreddits = re.findall(subreddit_pattern, markdown_content)
        knowledge_base['mentioned_subreddits'] = list(set(subreddits))

        return knowledge_base

    def save_knowledge_base(self, data: Dict[str, Any], format: str = 'both'):
        """
        Save the knowledge base in JSON and/or Markdown format
        """
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

        if format in ['json', 'both']:
            filename = f'reddit_wiki_kb_{timestamp}.json'
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            print(f"✅ JSON saved to: {filename}")

        if format in ['md', 'markdown', 'both']:
            filename = f'reddit_wiki_kb_{timestamp}.md'
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(f"# Reddit Wiki Knowledge Base\n\n")
                f.write(f"*Source: {data['source']}*\n")
                f.write(f"*Scraped: {data['scraped_at']}*\n\n")

                # Summary statistics
                f.write("## Summary\n\n")
                f.write(f"- Total Links: {len(data['all_links'])}\n")
                f.write(f"- Reddit Links: {len([l for l in data['all_links'] if l['is_reddit']])}\n")
                f.write(f"- External Links: {len([l for l in data['all_links'] if l['is_external']])}\n")
                f.write(f"- Categories: {len(data['categories'])}\n")
                f.write(f"- Mentioned Users: {len(data.get('mentioned_users', []))}\n")
                f.write(f"- Mentioned Subreddits: {len(data.get('mentioned_subreddits', []))}\n\n")

                # Categories and links
                f.write("## Categories and Links\n\n")
                for category, content in data['categories'].items():
                    f.write(f"### {category}\n\n")

                    # Direct links in category
                    if content['links']:
                        for link in content['links']:
                            icon = "🔗" if link['is_external'] else "📄"
                            f.write(f"- {icon} [{link['text']}]({link['url']})\n")
                        f.write("\n")

                    # Subsections
                    for subsection, sub_content in content['subsections'].items():
                        f.write(f"#### {subsection}\n\n")
                        if isinstance(sub_content, list):
                            for item in sub_content:
                                if isinstance(item, dict):
                                    if 'title' in item:
                                        f.write(f"##### {item['title']}\n\n")
                                    if 'links' in item:
                                        for link in item['links']:
                                            icon = "🔗" if link['is_external'] else "📄"
                                            f.write(f"- {icon} [{link['text']}]({link['url']})\n")
                                else:
                                    icon = "🔗" if item.get('is_external') else "📄"
                                    f.write(f"- {icon} [{item.get('text', '')}]({item.get('url', '')})\n")
                        f.write("\n")

                # All links reference
                f.write("\n## Complete Link Reference\n\n")
                f.write("### External Resources\n\n")
                for link in data['all_links']:
                    if link['is_external']:
                        f.write(f"- [{link['text']}]({link['url']}) - *{link.get('section', 'General')}*\n")

                f.write("\n### Reddit Links\n\n")
                for link in data['all_links']:
                    if link['is_reddit']:
                        f.write(f"- [{link['text']}]({link['url']}) - *{link.get('section', 'General')}*\n")

                # Mentioned users and subreddits
                if data.get('mentioned_users'):
                    f.write("\n### Mentioned Users\n\n")
                    for user in data['mentioned_users']:
                        f.write(f"- u/{user}\n")

                if data.get('mentioned_subreddits'):
                    f.write("\n### Related Subreddits\n\n")
                    for sub in data['mentioned_subreddits']:
                        f.write(f"- r/{sub}\n")

            print(f"✅ Markdown saved to: {filename}")

def main():
    scraper = RedditWikiJSONScraper()

    # Scrape the main wiki page
    print("="*50)
    print("Reddit Wiki JSON Scraper")
    print("="*50)

    wiki_data = scraper.fetch_wiki_json("TheScienceOfPE", "index")

    if wiki_data['success']:
        print(f"✅ Successfully fetched wiki content")
        print(f"   Revision by: {wiki_data.get('revision_by', 'Unknown')}")

        # Parse the content for links and structure
        knowledge_base = scraper.parse_markdown_for_links(wiki_data['content'])

        # Save the knowledge base
        scraper.save_knowledge_base(knowledge_base)

        # Print summary
        print("\n" + "="*50)
        print("SUMMARY")
        print("="*50)
        print(f"Total Links Found: {len(knowledge_base['all_links'])}")
        print(f"Categories: {len(knowledge_base['categories'])}")
        print(f"External Links: {len([l for l in knowledge_base['all_links'] if l['is_external']])}")
        print(f"Reddit Links: {len([l for l in knowledge_base['all_links'] if l['is_reddit']])}")

        # Print categories
        print("\nCategories Found:")
        for category in knowledge_base['categories'].keys():
            print(f"  - {category}")

    else:
        print(f"❌ Failed to fetch wiki: {wiki_data['error']}")
        print("\nTroubleshooting:")
        print("1. Check if the wiki is public")
        print("2. Try accessing it in a browser first")
        print("3. The subreddit might require authentication")

if __name__ == "__main__":
    main()