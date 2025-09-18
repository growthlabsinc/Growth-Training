#!/bin/bash

# Complete Image Replacement Process for Growth App
# This script runs all steps needed to replace placeholder images

set -e  # Exit on error

echo "🚀 Starting complete image replacement process..."
echo ""

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo ""
fi

# Step 1: Analyze current placeholders
echo "1️⃣ Analyzing current placeholder images..."
npm run analyze-images
echo ""
echo "✅ Analysis complete. Check placeholder-analysis-report.md for details."
echo ""

# Ask user to continue
read -p "Review the analysis report. Continue with replacement? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Process cancelled."
    exit 1
fi

# Step 2: Replace placeholder images
echo ""
echo "2️⃣ Downloading replacement images from Unsplash..."
npm run replace-images
echo ""

# Check if images were downloaded
if [ ! -d "downloaded-images" ] || [ -z "$(ls -A downloaded-images)" ]; then
    echo "❌ No images were downloaded. Check for errors above."
    exit 1
fi

echo "✅ Images downloaded successfully."
echo ""

# Step 3: Check for ImageMagick
if ! command -v convert &> /dev/null; then
    echo "⚠️  ImageMagick is not installed. Skipping optimization step."
    echo "To install: brew install imagemagick (macOS) or sudo apt-get install imagemagick (Linux)"
    echo ""
    echo "You can run optimization later with: npm run optimize-images"
else
    # Step 4: Optimize images for iOS
    echo "3️⃣ Optimizing images for iOS (generating @2x and @3x versions)..."
    npm run optimize-images
    echo ""
    echo "✅ Image optimization complete."
fi

# Summary
echo ""
echo "🎉 Image replacement process complete!"
echo ""
echo "📋 Next steps:"
echo "1. Review images in scripts/downloaded-images/"
echo "2. Check updated images in Growth/Assets.xcassets/"
echo "3. Build and run the app to test new images"
echo "4. Review attributions.json for licensing info"
echo "5. Commit all changes to version control"
echo ""
echo "📝 Important files:"
echo "- placeholder-analysis-report.md - Analysis of placeholders"
echo "- downloaded-images/attributions.json - Image credits (keep for licensing)"
echo "- ../Growth/Assets.xcassets/ - Updated app images"
echo "- ../data/sample-resources.json - Updated educational resource URLs"