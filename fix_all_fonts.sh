#!/bin/bash

# Script to fix ALL font references in the Growth app

echo "Fixing all font references in Growth app..."

# Fix standard .font(.xxx) patterns to use AppTheme.Typography
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.largeTitle)/\.font(AppTheme.Typography.largeTitleFont())/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.title)/\.font(AppTheme.Typography.title1Font())/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.title2)/\.font(AppTheme.Typography.title2Font())/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.title3)/\.font(AppTheme.Typography.title3Font())/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.headline)/\.font(AppTheme.Typography.headlineFont())/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.body)/\.font(AppTheme.Typography.bodyFont())/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.callout)/\.font(AppTheme.Typography.calloutFont())/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.subheadline)/\.font(AppTheme.Typography.subheadlineFont())/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.footnote)/\.font(AppTheme.Typography.footnoteFont())/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.caption)/\.font(AppTheme.Typography.captionFont())/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.caption2)/\.font(AppTheme.Typography.captionFont())/g' {} +

# Fix .custom font references
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.custom("Gravity-Bold", size: \([0-9]*\)))/\.font(AppTheme.Typography.gravityBoldFont(\1))/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.custom("gravity-bold", size: \([0-9]*\)))/\.font(AppTheme.Typography.gravityBoldFont(\1))/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.custom("Gravity-Light", size: \([0-9]*\)))/\.font(AppTheme.Typography.gravityLight(\1))/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.custom("gravity-light", size: \([0-9]*\)))/\.font(AppTheme.Typography.gravityLight(\1))/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.custom("Inter-Bold", size: \([0-9]*\)))/\.font(AppTheme.Typography.gravityBoldFont(\1))/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.custom("Inter-Medium", size: \([0-9]*\)))/\.font(AppTheme.Typography.gravitySemibold(\1))/g' {} +
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.custom("Inter-Regular", size: \([0-9]*\)))/\.font(AppTheme.Typography.gravityBook(\1))/g' {} +

# Fix .interTitle usage
find ./Growth ./GrowthTimerWidget -name "*.swift" -type f -exec sed -i '' 's/\.font(\.interTitle)/\.font(AppTheme.Typography.title1Font())/g' {} +

echo "Font references fixed!"
echo "Summary of changes:"
echo "- Standard font styles (.body, .headline, etc.) -> AppTheme.Typography methods"
echo "- Custom fonts -> AppTheme.Typography methods"
echo "- Inter fonts -> Gravity equivalents"