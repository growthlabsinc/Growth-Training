#!/bin/bash

cd /Users/tradeflowj/Desktop/Growth

# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*

# Build and capture errors
xcodebuild \
  -project Growth.xcodeproj \
  -scheme Growth \
  -sdk iphonesimulator18.5 \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build 2>&1 | tee build_output.txt | grep -E "(error:|warning:|⚠️|❌|failed|Failed)"

# Check if build succeeded
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "Build succeeded!"
else
    echo "Build failed!"
    echo "Checking for errors in build output..."
    grep -A5 -B5 "error:" build_output.txt | head -100
fi