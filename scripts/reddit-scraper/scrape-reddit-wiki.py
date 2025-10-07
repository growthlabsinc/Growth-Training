#!/usr/bin/env python3
"""
Reddit Wiki Scraper for TheScienceOfPE
Extracts all links and content from Reddit wiki pages
"""

import json
import asyncio
import sys
from datetime import datetime
from typing import Dict, List, Any
from playwright.async_api import async_playwright

class RedditWikiScraper:
    def __init__(self):
        self.base_url = "https://www.reddit.com"
        self.wiki_data = {
            "source": "r/TheScienceOfPE Wiki",
            "scraped_at": datetime.now().isoformat(),
            "sections": [],
            "links": []
        }

    async def scrape_wiki(self, url: str) -> Dict[str, Any]:
        """
        Scrape a Reddit wiki page and extract all links and content
        """
        async with async_playwright() as p:
            # Launch browser in headless mode
            browser = await p.chromium.launch(
                headless=True,
                args=[
                    '--disable-blink-features=AutomationControlled',
                    '--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
                ]
            )

            context = await browser.new_context(
                viewport={'width': 1920, 'height': 1080},
                user_agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
            )

            page = await context.new_page()

            try:
                print(f"Navigating to: {url}")
                await page.goto(url, wait_until='networkidle', timeout=30000)

                # Wait for wiki content to load
                await page.wait_for_selector('.wiki-page-content', timeout=10000)

                # Extract the main content
                content = await page.evaluate('''() => {
                    const wikiContent = document.querySelector('.wiki-page-content');
                    if (!wikiContent) return null;

                    const data = {
                        title: document.title,
                        sections: [],
                        links: []
                    };

                    // Process headers and content
                    const headers = wikiContent.querySelectorAll('h1, h2, h3, h4');
                    headers.forEach(header => {
                        const section = {
                            level: header.tagName.toLowerCase(),
                            title: header.textContent.trim(),
                            content: [],
                            links: []
                        };

                        // Get content after this header until next header
                        let nextElement = header.nextElementSibling;
                        while (nextElement && !['H1', 'H2', 'H3', 'H4'].includes(nextElement.tagName)) {
                            if (nextElement.tagName === 'P' || nextElement.tagName === 'UL' || nextElement.tagName === 'OL') {
                                section.content.push(nextElement.textContent.trim());

                                // Extract links from this element
                                const links = nextElement.querySelectorAll('a');
                                links.forEach(link => {
                                    const linkData = {
                                        text: link.textContent.trim(),
                                        href: link.href,
                                        isExternal: !link.href.includes('reddit.com'),
                                        section: section.title
                                    };
                                    section.links.push(linkData);
                                    data.links.push(linkData);
                                });
                            }
                            nextElement = nextElement.nextElementSibling;
                        }

                        data.sections.push(section);
                    });

                    // Get all links if sections didn't capture them all
                    const allLinks = wikiContent.querySelectorAll('a');
                    allLinks.forEach(link => {
                        const href = link.href;
                        if (href && !data.links.find(l => l.href === href)) {
                            data.links.push({
                                text: link.textContent.trim(),
                                href: href,
                                isExternal: !href.includes('reddit.com'),
                                section: 'Unknown'
                            });
                        }
                    });

                    return data;
                }''')

                if content:
                    self.wiki_data = {**self.wiki_data, **content}
                    print(f"Successfully scraped {len(content.get('links', []))} links")
                else:
                    print("Could not find wiki content on the page")

            except Exception as e:
                print(f"Error scraping page: {e}")

            finally:
                await browser.close()

        return self.wiki_data

    def save_to_json(self, filename: str = "reddit_wiki_knowledge_base.json"):
        """Save scraped data to JSON file"""
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(self.wiki_data, f, indent=2, ensure_ascii=False)
        print(f"Data saved to {filename}")

    def save_to_markdown(self, filename: str = "reddit_wiki_knowledge_base.md"):
        """Save scraped data as formatted markdown"""
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(f"# {self.wiki_data.get('title', 'Reddit Wiki Knowledge Base')}\n\n")
            f.write(f"*Scraped on: {self.wiki_data['scraped_at']}*\n\n")

            # Write sections
            for section in self.wiki_data.get('sections', []):
                level = '#' * int(section['level'][1]) if section['level'].startswith('h') else '##'
                f.write(f"\n{level} {section['title']}\n\n")

                # Write content
                for content in section.get('content', []):
                    if content:
                        f.write(f"{content}\n\n")

                # Write links for this section
                if section.get('links'):
                    f.write("### Links in this section:\n\n")
                    for link in section['links']:
                        external = "🔗" if link.get('isExternal') else "📄"
                        f.write(f"- {external} [{link['text']}]({link['href']})\n")
                    f.write("\n")

            # Write all links summary
            f.write("\n## All Links\n\n")

            # Group links by external/internal
            external_links = [l for l in self.wiki_data.get('links', []) if l.get('isExternal')]
            internal_links = [l for l in self.wiki_data.get('links', []) if not l.get('isExternal')]

            if external_links:
                f.write("### External Links\n\n")
                for link in external_links:
                    f.write(f"- [{link['text']}]({link['href']}) - Section: {link.get('section', 'N/A')}\n")

            if internal_links:
                f.write("\n### Reddit Internal Links\n\n")
                for link in internal_links:
                    f.write(f"- [{link['text']}]({link['href']}) - Section: {link.get('section', 'N/A')}\n")

        print(f"Markdown saved to {filename}")

async def main():
    # The wiki URL to scrape
    wiki_url = "https://www.reddit.com/r/TheScienceOfPE/wiki/index/"

    if len(sys.argv) > 1:
        wiki_url = sys.argv[1]

    print(f"Starting Reddit Wiki Scraper")
    print(f"Target URL: {wiki_url}")
    print("-" * 50)

    scraper = RedditWikiScraper()

    # Scrape the wiki
    data = await scraper.scrape_wiki(wiki_url)

    # Save results
    if data.get('links'):
        scraper.save_to_json()
        scraper.save_to_markdown()

        print(f"\n Summary:")
        print(f"- Total sections: {len(data.get('sections', []))}")
        print(f"- Total links: {len(data.get('links', []))}")
        print(f"- External links: {len([l for l in data.get('links', []) if l.get('isExternal')])}")
        print(f"- Internal links: {len([l for l in data.get('links', []) if not l.get('isExternal')])}")
    else:
        print("No data was scraped. The page might require authentication or have anti-bot measures.")

if __name__ == "__main__":
    asyncio.run(main())