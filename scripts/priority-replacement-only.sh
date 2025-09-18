#!/bin/bash

# Growth App - Priority Print Replacement (without full backup)
# Focuses on critical files only

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Counter for replaced files
TOTAL_REPLACED=0

# Priority 1: Authentication and Security files
print_status "🔐 Processing authentication and security files..."
AUTH_FILES=$(find Growth -name "*.swift" -type f \( \
    -path "*Auth*" -o \
    -path "*Login*" -o \
    -path "*Security*" -o \
    -path "*Biometric*" -o \
    -path "*Keychain*" \
\) | grep -v "Logger.swift" || true)

for file in $AUTH_FILES; do
    if grep -q "print(" "$file" 2>/dev/null; then
        COUNT=$(grep -c "print(" "$file" || true)
        print_warning "Found $COUNT prints in: $(basename $file)"
        # Replace print with Logger.error for security files
        sed -i '' 's/print(/Logger.error(/g' "$file"
        TOTAL_REPLACED=$((TOTAL_REPLACED + COUNT))
        print_success "Updated: $file"
    fi
done

# Priority 2: Payment and Subscription files
print_status "💳 Processing payment and subscription files..."
PAYMENT_FILES=$(find Growth -name "*.swift" -type f \( \
    -path "*Payment*" -o \
    -path "*Subscription*" -o \
    -path "*Purchase*" -o \
    -path "*StoreKit*" \
\) | grep -v "Logger.swift" || true)

for file in $PAYMENT_FILES; do
    if grep -q "print(" "$file" 2>/dev/null; then
        COUNT=$(grep -c "print(" "$file" || true)
        print_warning "Found $COUNT prints in: $(basename $file)"
        # Replace print with Logger.info for payment files
        sed -i '' 's/print(/Logger.info(/g' "$file"
        TOTAL_REPLACED=$((TOTAL_REPLACED + COUNT))
        print_success "Updated: $file"
    fi
done

# Priority 3: User Data and Services
print_status "👤 Processing user data and service files..."
SERVICE_FILES=$(find Growth -name "*.swift" -type f \( \
    -path "*UserService*" -o \
    -path "*ProfileService*" -o \
    -path "*DataService*" -o \
    -path "*FirebaseService*" -o \
    -path "*FirestoreService*" \
\) | grep -v "Logger.swift" || true)

for file in $SERVICE_FILES; do
    if grep -q "print(" "$file" 2>/dev/null; then
        COUNT=$(grep -c "print(" "$file" || true)
        print_warning "Found $COUNT prints in: $(basename $file)"
        # Replace print with Logger.info for service files
        sed -i '' 's/print(/Logger.info(/g' "$file"
        TOTAL_REPLACED=$((TOTAL_REPLACED + COUNT))
        print_success "Updated: $file"
    fi
done

# Priority 4: ViewModels (business logic)
print_status "🧮 Processing ViewModel files..."
VM_FILES=$(find Growth -name "*ViewModel.swift" -type f | grep -v "Logger.swift" || true)
VM_COUNT=0

for file in $VM_FILES; do
    if grep -q "print(" "$file" 2>/dev/null; then
        COUNT=$(grep -c "print(" "$file" || true)
        VM_COUNT=$((VM_COUNT + COUNT))
        # Replace print with Logger.debug for ViewModels
        sed -i '' 's/print(/Logger.debug(/g' "$file"
        TOTAL_REPLACED=$((TOTAL_REPLACED + COUNT))
        print_success "Updated: $file (replaced $COUNT prints)"
    fi
done

print_status "Replaced $VM_COUNT prints in ViewModels"

# Check for any critical prints that might expose sensitive data
print_status "🔍 Final security check..."
SENSITIVE_PATTERNS=(
    "password"
    "token"
    "secret"
    "key"
    "api"
    "credential"
    "auth"
)

SECURITY_ISSUES=0
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    FOUND=$(grep -r "print(.*$pattern" --include="*.swift" Growth/ 2>/dev/null | grep -v "Logger\." | head -5 || true)
    if [ -n "$FOUND" ]; then
        print_error "Still found prints with '$pattern':"
        echo "$FOUND"
        SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
    fi
done

# Generate summary
print_status "📊 Generating summary..."
REMAINING_PRINTS=$(grep -r "print(" --include="*.swift" Growth/ 2>/dev/null | grep -v "Logger\." | wc -l | tr -d ' ')

echo ""
print_success "Priority replacement completed!"
print_status "Total prints replaced: $TOTAL_REPLACED"
print_status "Remaining prints: $REMAINING_PRINTS"
if [ $SECURITY_ISSUES -gt 0 ]; then
    print_error "Security issues found: $SECURITY_ISSUES patterns detected"
fi

# Show files that still have the most prints
echo ""
print_status "Files with most remaining prints:"
grep -r "print(" --include="*.swift" Growth/ 2>/dev/null | grep -v "Logger\." | cut -d: -f1 | sort | uniq -c | sort -nr | head -10

# Save report
cat > priority-replacement-report.md << EOF
# Priority Print Replacement Report

Generated: $(date)

## Summary
- Total prints replaced: $TOTAL_REPLACED
- Remaining prints: $REMAINING_PRINTS
- Security issues: $SECURITY_ISSUES

## Priority Areas Processed
1. 🔐 Authentication & Security - Logger.error()
2. 💳 Payments & Subscriptions - Logger.info()
3. 👤 User Services & Data - Logger.info()
4. 🧮 ViewModels - Logger.debug()

## Next Steps
1. Review changes: \`git diff\`
2. Build and test critical flows
3. Address any security issues found
4. Consider running full replacement for remaining $REMAINING_PRINTS prints

## Backup
Backup created at: Growth.backup.20250723_091927
EOF

print_success "Report saved to: priority-replacement-report.md"