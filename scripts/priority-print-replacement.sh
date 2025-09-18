#!/bin/bash

# Growth App - Priority-based Print Statement Replacement
# This script replaces print statements in priority order

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

# Create backup
BACKUP_DIR="Growth.backup.$(date +%Y%m%d_%H%M%S)"
print_status "Creating backup..."
cp -r Growth "$BACKUP_DIR"
print_success "Backup created at: $BACKUP_DIR"

# Priority 1: Authentication and Security files
print_status "🔐 Processing authentication and security files..."
find Growth -name "*.swift" -type f \( \
    -path "*Auth*" -o \
    -path "*Login*" -o \
    -path "*Security*" -o \
    -path "*Biometric*" -o \
    -path "*Keychain*" \
\) | while read -r file; do
    if grep -q "print(" "$file"; then
        print_warning "Found prints in security file: $file"
        # Replace print with Logger.error for security files
        sed -i '' 's/print(/Logger.error(/g' "$file"
        print_success "Updated: $file"
    fi
done

# Priority 2: Payment and Subscription files
print_status "💳 Processing payment and subscription files..."
find Growth -name "*.swift" -type f \( \
    -path "*Payment*" -o \
    -path "*Subscription*" -o \
    -path "*Purchase*" -o \
    -path "*StoreKit*" \
\) | while read -r file; do
    if grep -q "print(" "$file"; then
        print_warning "Found prints in payment file: $file"
        # Replace print with Logger.info for payment files
        sed -i '' 's/print(/Logger.info(/g' "$file"
        print_success "Updated: $file"
    fi
done

# Priority 3: User Data and Services
print_status "👤 Processing user data and service files..."
find Growth -name "*.swift" -type f \( \
    -path "*UserService*" -o \
    -path "*ProfileService*" -o \
    -path "*DataService*" -o \
    -path "*FirebaseService*" \
\) | while read -r file; do
    if grep -q "print(" "$file"; then
        print_warning "Found prints in service file: $file"
        # Replace print with Logger.info for service files
        sed -i '' 's/print(/Logger.info(/g' "$file"
        print_success "Updated: $file"
    fi
done

# Priority 4: ViewModels (business logic)
print_status "🧮 Processing ViewModel files..."
find Growth -name "*ViewModel.swift" -type f | while read -r file; do
    if grep -q "print(" "$file"; then
        # Replace print with Logger.debug for ViewModels
        sed -i '' 's/print(/Logger.debug(/g' "$file"
        print_success "Updated: $file"
    fi
done

# Check for any critical prints that might expose sensitive data
print_status "🔍 Checking for sensitive data exposure..."
SENSITIVE_PATTERNS=(
    "password"
    "token"
    "secret"
    "key"
    "api"
    "credential"
    "auth"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    FOUND=$(grep -r "print(.*$pattern" --include="*.swift" Growth/ 2>/dev/null | grep -v "Logger\." || true)
    if [ -n "$FOUND" ]; then
        print_error "Found potential sensitive data in print statements containing '$pattern':"
        echo "$FOUND" | head -10
    fi
done

# Generate summary report
print_status "📊 Generating summary..."
REMAINING_PRINTS=$(grep -r "print(" --include="*.swift" Growth/ | grep -v "Logger\." | wc -l | tr -d ' ')

cat > priority-replacement-report.md << EOF
# Priority Print Replacement Report

Generated: $(date)

## Files Processed by Priority

### 🔐 Priority 1: Security & Authentication
- Replaced prints with Logger.error()
- These are critical for security

### 💳 Priority 2: Payments & Subscriptions  
- Replaced prints with Logger.info()
- Important for transaction tracking

### 👤 Priority 3: User Data & Services
- Replaced prints with Logger.info()
- Important for data flow tracking

### 🧮 Priority 4: ViewModels
- Replaced prints with Logger.debug()
- Business logic debugging

## Status
- Backup created at: $BACKUP_DIR
- Remaining print statements: $REMAINING_PRINTS

## Next Steps
1. Review the changes: \`git diff\`
2. Build and test critical flows:
   - Authentication
   - Payment processing
   - User data operations
3. Run full print replacement for remaining files if needed

## Important Notes
- Only high-priority files were processed
- UI component prints were not changed (lower priority)
- Review any remaining sensitive prints manually
EOF

print_success "Report saved to: priority-replacement-report.md"

print_status "Summary:"
print_status "- Remaining prints: $REMAINING_PRINTS"
print_status "- Backup location: $BACKUP_DIR"
print_warning "Please review changes and test critical flows!"

# Show sample of remaining prints
if [ "$REMAINING_PRINTS" -gt 0 ]; then
    echo ""
    print_status "Sample of remaining print statements:"
    grep -r "print(" --include="*.swift" Growth/ | grep -v "Logger\." | head -5
fi