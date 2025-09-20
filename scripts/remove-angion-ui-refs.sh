#!/bin/bash

# Script to remove hardcoded Angion method references from UI files

echo "🧹 Removing hardcoded Angion method references from UI files..."

# Files to process
FILES=$(find /Users/tradeflowj/Desktop/Dev/growth-training/Growth -name "*.swift" -exec grep -l "am[123]_0\|angion_method\|sabre_type" {} \;)

# Count files
FILE_COUNT=$(echo "$FILES" | wc -l | tr -d ' ')
echo "Found $FILE_COUNT files with potential Angion references"

# Process each file
for file in $FILES; do
    echo "Processing: $(basename $file)"

    # Create backup
    cp "$file" "${file}.bak"

    # Remove image references for Angion methods
    sed -i '' '/Image("am[123]_0")/d' "$file"
    sed -i '' '/Image("angion_method/d' "$file"
    sed -i '' '/Image("sabre/d' "$file"

    # Remove conditionals checking for Angion method IDs
    sed -i '' '/method\.id == "am[123]_0"/d' "$file"
    sed -i '' '/method\.id == "angion_method/d' "$file"
    sed -i '' '/method\.id == "sabre/d' "$file"
    sed -i '' '/methodId == "am[123]_0"/d' "$file"

    # Remove string literals referencing Angion methods
    sed -i '' 's/"am[123]_0"//g' "$file"
    sed -i '' 's/"angion_method[^"]*"//g' "$file"
    sed -i '' 's/"sabre_type_[abcd]"//g' "$file"

    # Check if file was modified
    if ! diff -q "$file" "${file}.bak" > /dev/null; then
        echo "  ✅ Updated $(basename $file)"
        rm "${file}.bak"
    else
        echo "  ⏭️  No changes needed in $(basename $file)"
        rm "${file}.bak"
    fi
done

echo "✅ Cleanup complete!"