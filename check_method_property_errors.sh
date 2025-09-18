#!/bin/bash

# Script to check for potential method and property access errors in Swift code
# This helps identify cases where code might be accessing non-existent methods or properties

echo "=== Checking for potential method and property access errors ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create a temporary directory for analysis
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Function to extract class/struct definitions and their members
extract_type_definitions() {
    local file=$1
    local type_name=$2
    
    # Extract the type definition including its properties and methods
    awk -v type="$type_name" '
    BEGIN { in_type = 0; brace_count = 0; }
    /^[[:space:]]*(class|struct|protocol|extension)[[:space:]]+'type'[[:space:]]*[:{\[]/ {
        in_type = 1;
        brace_count = 0;
    }
    in_type {
        print;
        brace_count += gsub(/{/, "{");
        brace_count -= gsub(/}/, "}");
        if (brace_count == 0 && /}/) {
            in_type = 0;
        }
    }
    ' "$file"
}

# Function to extract property and method names from a type
extract_members() {
    local type_def=$1
    
    # Extract properties (var/let declarations)
    echo "$type_def" | grep -E '^\s*(var|let)\s+[a-zA-Z_][a-zA-Z0-9_]*' | \
        sed -E 's/^\s*(var|let)\s+([a-zA-Z_][a-zA-Z0-9_]*).*/\2/' | sort -u
    
    # Extract methods (func declarations)
    echo "$type_def" | grep -E '^\s*func\s+[a-zA-Z_][a-zA-Z0-9_]*' | \
        sed -E 's/^\s*func\s+([a-zA-Z_][a-zA-Z0-9_]*).*/\1/' | sort -u
    
    # Extract computed properties (var with { get/set })
    echo "$type_def" | grep -E '^\s*var\s+[a-zA-Z_][a-zA-Z0-9_]*.*{' | \
        sed -E 's/^\s*var\s+([a-zA-Z_][a-zA-Z0-9_]*).*/\1/' | sort -u
}

# Step 1: Find all ViewModels and their definitions
echo -e "${BLUE}Step 1: Analyzing ViewModels...${NC}"
find . -name "*.swift" -path "*/ViewModels/*" | while read -r file; do
    # Extract ViewModel class names
    grep -E '^\s*class\s+[a-zA-Z_][a-zA-Z0-9_]*ViewModel' "$file" | \
        sed -E 's/^\s*class\s+([a-zA-Z_][a-zA-Z0-9_]*ViewModel).*/\1/' | \
        while read -r viewmodel; do
            echo -e "${GREEN}Found ViewModel: $viewmodel in $file${NC}"
            
            # Extract and save the ViewModel definition
            extract_type_definitions "$file" "$viewmodel" > "$TEMP_DIR/${viewmodel}_definition.txt"
            
            # Extract members
            members=$(extract_members "$(cat "$TEMP_DIR/${viewmodel}_definition.txt")")
            echo "$members" > "$TEMP_DIR/${viewmodel}_members.txt"
            
            # Show member count
            member_count=$(echo "$members" | grep -v '^$' | wc -l)
            echo "  - Found $member_count members"
        done
done

echo ""

# Step 2: Find all Services and their definitions
echo -e "${BLUE}Step 2: Analyzing Services...${NC}"
find . -name "*.swift" -path "*/Services/*" | while read -r file; do
    # Extract Service class names
    grep -E '^\s*class\s+[a-zA-Z_][a-zA-Z0-9_]*Service' "$file" | \
        sed -E 's/^\s*class\s+([a-zA-Z_][a-zA-Z0-9_]*Service).*/\1/' | \
        while read -r service; do
            echo -e "${GREEN}Found Service: $service in $file${NC}"
            
            # Extract and save the Service definition
            extract_type_definitions "$file" "$service" > "$TEMP_DIR/${service}_definition.txt"
            
            # Extract members
            members=$(extract_members "$(cat "$TEMP_DIR/${service}_definition.txt")")
            echo "$members" > "$TEMP_DIR/${service}_members.txt"
            
            # Show member count
            member_count=$(echo "$members" | grep -v '^$' | wc -l)
            echo "  - Found $member_count members"
        done
done

echo ""

# Step 3: Check for potential access errors
echo -e "${BLUE}Step 3: Checking for potential access errors...${NC}"
echo ""

# Function to check if a member exists in a type
check_member_exists() {
    local type=$1
    local member=$2
    local members_file="$TEMP_DIR/${type}_members.txt"
    
    if [ -f "$members_file" ]; then
        grep -q "^${member}$" "$members_file"
        return $?
    fi
    return 1
}

# Find all Swift files and check for potential errors
find . -name "*.swift" -not -path "./DerivedData/*" -not -path "./.build/*" | while read -r file; do
    # Skip definition files themselves
    if [[ "$file" == *"/ViewModels/"* ]] || [[ "$file" == *"/Services/"* ]]; then
        continue
    fi
    
    # Look for ViewModel property/method access
    grep -n -E 'viewModel\.[a-zA-Z_][a-zA-Z0-9_]*' "$file" | while IFS=: read -r line_num line; do
        # Extract the accessed member
        member=$(echo "$line" | sed -E 's/.*viewModel\.([a-zA-Z_][a-zA-Z0-9_]*).*/\1/')
        
        # Try to determine which ViewModel is being used
        # Look for @StateObject, @ObservedObject, or property declarations
        viewmodel_type=$(grep -B 20 "viewModel\.$member" "$file" | \
            grep -E '@(StateObject|ObservedObject|EnvironmentObject).*ViewModel|let viewModel.*ViewModel|var viewModel.*ViewModel' | \
            tail -1 | \
            sed -E 's/.*[[:space:]]([a-zA-Z_][a-zA-Z0-9_]*ViewModel).*/\1/')
        
        if [ -n "$viewmodel_type" ]; then
            if ! check_member_exists "$viewmodel_type" "$member"; then
                echo -e "${RED}Potential Error:${NC} $file:$line_num"
                echo -e "  Accessing '${YELLOW}$member${NC}' on ${BLUE}$viewmodel_type${NC}"
                echo -e "  Line: $line"
                echo ""
            fi
        fi
    done
    
    # Look for Service property/method access
    grep -n -E '[a-zA-Z_][a-zA-Z0-9_]*Service\.(shared\.)?[a-zA-Z_][a-zA-Z0-9_]*' "$file" | while IFS=: read -r line_num line; do
        # Extract service and member
        if echo "$line" | grep -q '\.shared\.'; then
            service=$(echo "$line" | sed -E 's/.*([a-zA-Z_][a-zA-Z0-9_]*Service)\.shared\..*/\1/')
            member=$(echo "$line" | sed -E 's/.*\.shared\.([a-zA-Z_][a-zA-Z0-9_]*).*/\1/')
        else
            service=$(echo "$line" | sed -E 's/.*([a-zA-Z_][a-zA-Z0-9_]*Service)\./\1/')
            member=$(echo "$line" | sed -E 's/.*Service\.([a-zA-Z_][a-zA-Z0-9_]*).*/\1/')
        fi
        
        if [ -n "$service" ] && [ -n "$member" ] && [ "$member" != "shared" ]; then
            if ! check_member_exists "$service" "$member"; then
                echo -e "${RED}Potential Error:${NC} $file:$line_num"
                echo -e "  Accessing '${YELLOW}$member${NC}' on ${BLUE}$service${NC}"
                echo -e "  Line: $line"
                echo ""
            fi
        fi
    done
done

# Step 4: Check for common patterns that might indicate errors
echo -e "${BLUE}Step 4: Checking for common error patterns...${NC}"
echo ""

# Check for 'Value of type ... has no member' in comments (might indicate unresolved errors)
echo -e "${YELLOW}Checking for commented error indicators...${NC}"
grep -r "has no member\|has no dynamic member\|Cannot call value of non-function type" . \
    --include="*.swift" \
    --exclude-dir=DerivedData \
    --exclude-dir=.build | while IFS=: read -r file line; do
    echo -e "${RED}Found error indicator in:${NC} $file"
    echo "  $line"
    echo ""
done

# Check for methods with similar names (might indicate typos)
echo -e "${YELLOW}Checking for potential typos in method names...${NC}"
for members_file in "$TEMP_DIR"/*_members.txt; do
    if [ -f "$members_file" ]; then
        type_name=$(basename "$members_file" _members.txt)
        
        # Common typo patterns
        grep -E '^refresh' "$members_file" | while read -r method; do
            # Check if 'refresh' is called but 'refreshMethods' exists
            if [ "$method" = "refreshMethods" ]; then
                grep -r "\.refresh()" . --include="*.swift" | grep -v "\.refreshMethods" | \
                    grep "$type_name" | while IFS=: read -r file line; do
                    echo -e "${YELLOW}Potential Typo:${NC} $file"
                    echo "  Found '.refresh()' but type has 'refreshMethods()'"
                    echo "  Line: $line"
                    echo ""
                done
            fi
        done
        
        # Check for isEmpty vs empty confusion
        if grep -q "^empty$" "$members_file" && ! grep -q "^isEmpty$" "$members_file"; then
            grep -r "\.isEmpty" . --include="*.swift" | grep "$type_name" | \
                while IFS=: read -r file line; do
                echo -e "${YELLOW}Potential Typo:${NC} $file"
                echo "  Found '.isEmpty' but type has 'empty' property"
                echo "  Line: $line"
                echo ""
            done
        fi
    fi
done

# Step 5: Summary
echo -e "${BLUE}Step 5: Summary${NC}"
echo ""

# Count potential issues
error_count=$(find . -name "*.swift" -not -path "./DerivedData/*" -not -path "./.build/*" | \
    xargs grep -l "viewModel\.\|Service\." | wc -l)

echo "Analyzed Swift files for potential method/property access errors"
echo "Files scanned: $(find . -name "*.swift" -not -path "./DerivedData/*" -not -path "./.build/*" | wc -l)"
echo ""

# Provide recommendations
echo -e "${GREEN}Recommendations:${NC}"
echo "1. Review the potential errors listed above"
echo "2. For each error, either:"
echo "   - Fix the method/property name to match what's defined"
echo "   - Add the missing method/property to the type"
echo "   - Update the type definition if it's outdated"
echo "3. Run 'xcodebuild' to verify all errors are resolved"
echo ""

# Optional: Generate a fix script
echo -e "${YELLOW}Generating fix suggestions...${NC}"
cat > "$TEMP_DIR/suggested_fixes.txt" << EOF
# Suggested fixes based on analysis

# Common fixes found:
# 1. viewModel.refresh() -> viewModel.refreshMethods()
# 2. viewModel.isEmpty -> viewModel.filteredMethods.isEmpty
# 3. loadMethods(forceRefresh: true) -> loadMethods()

# To apply fixes automatically (review first!):
EOF

# Generate sed commands for common fixes
echo "# sed commands for common fixes:" >> "$TEMP_DIR/suggested_fixes.txt"
echo 'find . -name "*.swift" -exec sed -i "" "s/viewModel\.refresh()/viewModel.refreshMethods()/g" {} \;' >> "$TEMP_DIR/suggested_fixes.txt"
echo 'find . -name "*.swift" -exec sed -i "" "s/viewModel\.isEmpty/viewModel.filteredMethods.isEmpty/g" {} \;' >> "$TEMP_DIR/suggested_fixes.txt"

echo ""
echo -e "${GREEN}Fix suggestions saved to: $TEMP_DIR/suggested_fixes.txt${NC}"
echo ""

# Make the script executable
chmod +x "$0"