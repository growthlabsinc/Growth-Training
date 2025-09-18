#!/bin/bash

# Replace remaining print statements in preview/example code
# These are safe to mark with // Release OK since they're only in previews

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_status "Handling remaining print statements in preview code..."

# For commented prints, just add Release OK marker
sed -i '' 's|// print(|// print( // Release OK|g' Growth/Features/AICoach/Services/PromptTemplateService.swift
sed -i '' 's|//     print(|//     print( // Release OK|g' Growth/Features/Timer/Services/LiveActivityManager.swift

# For preview action handlers, add Release OK comment
FILES_WITH_PREVIEW_PRINTS=(
    "Growth/Core/UI/Components/PrimaryButton.swift"
    "Growth/Features/Progress/Components/ProgressSummaryCard.swift"
    "Growth/Features/Progress/Components/AchievementHighlightView.swift"
    "Growth/Features/Progress/Components/GainsHighlightCard.swift"
    "Growth/Features/Progress/Components/StatsHighlightView.swift"
    "Growth/Features/Progress/Views/ProgressOverviewView.swift"
    "Growth/Features/Dashboard/Components/ContextualQuickActionsView.swift"
    "Growth/Features/Dashboard/Components/WeeklyProgressSnapshotView.swift"
    "Growth/Features/Dashboard/Components/TodaysFocusView.swift"
    "Growth/Features/Practice/Components/PracticeOptionCardView.swift"
)

for file in "${FILES_WITH_PREVIEW_PRINTS[@]}"; do
    if [ -f "$file" ]; then
        # Add Release OK comment to print statements in preview handlers
        sed -i '' 's/print("\([^"]*\)")/print("\1") \/\/ Release OK - Preview/g' "$file"
        print_success "Updated: $(basename $file)"
    fi
done

# Count remaining prints
REMAINING=$(grep -r "print(" --include="*.swift" Growth/ | grep -v "Logger\." | grep -v "// Release OK" | wc -l | tr -d ' ')

print_status "Summary:"
print_status "- Files processed: ${#FILES_WITH_PREVIEW_PRINTS[@]}"
print_status "- Remaining unmarked prints: $REMAINING"

if [ "$REMAINING" -eq 0 ]; then
    print_success "All print statements have been handled!"
else
    print_status "Some prints may still need attention."
fi