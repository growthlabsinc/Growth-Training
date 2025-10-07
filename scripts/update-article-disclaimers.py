#!/usr/bin/env python3
"""
Update all article markdown files with standard medical disclaimer.
Replaces existing disclaimers with the 5-point standard disclaimer.
"""

import os
import re

STANDARD_DISCLAIMER = """## Medical Disclaimer

⚠️ **IMPORTANT HEALTH INFORMATION**

This information is for educational purposes only and does not constitute medical advice. Consult with a healthcare provider before beginning any exercise program.

Individual results may vary. This app does not guarantee specific outcomes or results from following the information provided.

Every individual's physiology is different. What works for one person may not work for another.

There are inherent risks associated with physical exercise programs. Stop immediately if you experience pain, discomfort, or unusual symptoms, and seek medical attention.

This app and its content are intended for adults 18 years of age and older only.

---"""

def update_article_disclaimer(filepath):
    """Update disclaimer in a single article file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find existing disclaimer section and replace it
    # Pattern matches: ## Medical Disclaimer ... (everything until next ## or end)
    pattern = r'## Medical Disclaimer\n\n.*?(?=\n---\n\n## References|\Z)'

    if re.search(pattern, content, re.DOTALL):
        # Replace existing disclaimer
        updated_content = re.sub(pattern, STANDARD_DISCLAIMER, content, flags=re.DOTALL)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(updated_content)

        print(f"✅ Updated: {os.path.basename(filepath)}")
        return True
    else:
        print(f"⚠️  No disclaimer found in: {os.path.basename(filepath)}")
        return False

def main():
    """Update all article files with standard disclaimer."""
    articles_dir = "docs/content-research/articles"

    updated_count = 0
    for filename in sorted(os.listdir(articles_dir)):
        if filename.startswith("article-") and filename.endswith(".md"):
            filepath = os.path.join(articles_dir, filename)
            if update_article_disclaimer(filepath):
                updated_count += 1

    print(f"\n📊 Summary: Updated {updated_count} articles with standard disclaimer")

if __name__ == "__main__":
    main()
