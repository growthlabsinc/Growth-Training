#!/bin/bash

# Script to update Firebase project ID from growth-training-app to growth-training-app

echo "🔄 Updating Firebase project ID from growth-training-app to growth-training-app..."

# Find and replace in all files
find . -type f \( -name "*.js" -o -name "*.swift" -o -name "*.md" -o -name "*.sh" -o -name "*.html" -o -name "*.plist" \) \
    -not -path "./node_modules/*" \
    -not -path "./.git/*" \
    -not -path "./functions/node_modules/*" \
    -not -path "./DerivedData/*" \
    -exec grep -l "growth-training-app" {} \; | while read file; do
    echo "Updating: $file"
    # Use sed to replace the old project ID with the new one
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' 's/growth-training-app/growth-training-app/g' "$file"
    else
        # Linux
        sed -i 's/growth-training-app/growth-training-app/g' "$file"
    fi
done

echo "✅ Firebase project ID update complete!"
echo ""
echo "⚠️  Important next steps:"
echo "1. Review the changes to ensure all updates are correct"
echo "2. Update any Firebase Console settings manually"
echo "3. Re-register App Check debug tokens in the new project"
echo "4. Update any CI/CD configurations"
echo "5. Test the app thoroughly with the new project"