#!/bin/bash

# Reset script for image replacement process
# Use this to clear caches and start fresh

echo "🧹 Resetting image replacement process..."
echo ""

# Remove rate limit cache
if [ -f ".unsplash-rate-limit.json" ]; then
    rm .unsplash-rate-limit.json
    echo "✅ Removed rate limit cache"
fi

# Remove progress cache
if [ -f ".image-replacement-progress.json" ]; then
    rm .image-replacement-progress.json
    echo "✅ Removed progress cache"
fi

# Ask about downloaded images
if [ -d "downloaded-images" ]; then
    echo ""
    read -p "Remove downloaded images directory? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf downloaded-images
        echo "✅ Removed downloaded images"
    else
        echo "ℹ️ Kept downloaded images"
    fi
fi

# Ask about analysis report
if [ -f "placeholder-analysis-report.md" ]; then
    echo ""
    read -p "Remove analysis report? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm placeholder-analysis-report.md
        echo "✅ Removed analysis report"
    else
        echo "ℹ️ Kept analysis report"
    fi
fi

echo ""
echo "✨ Reset complete! You can now run a fresh image replacement process."