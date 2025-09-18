#!/bin/bash

# Fix AppTheme capitalization issues throughout the codebase

echo "Fixing AppTheme.colors to AppTheme.Colors..."
find . -name "*.swift" -type f -exec sed -i '' 's/AppTheme\.colors\./AppTheme.Colors./g' {} +

echo "Fixing AppTheme.typography to AppTheme.Typography..."
find . -name "*.swift" -type f -exec sed -i '' 's/AppTheme\.typography\./AppTheme.Typography./g' {} +

echo "Fixing AppTheme.layout to AppTheme.Layout..."
find . -name "*.swift" -type f -exec sed -i '' 's/AppTheme\.layout\./AppTheme.Layout./g' {} +

echo "Fixing AppTheme.animation to AppTheme.Animation..."
find . -name "*.swift" -type f -exec sed -i '' 's/AppTheme\.animation\./AppTheme.Animation./g' {} +

echo "Done! All AppTheme references should now use proper capitalization."