#!/bin/bash

# Growth App - App Store Screenshot Capture Script
# This script helps automate the screenshot capture process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCREENSHOT_DIR="./AppStoreScreenshots"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

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

# Create screenshot directory
create_directories() {
    print_status "Creating screenshot directories..."
    mkdir -p "$SCREENSHOT_DIR/iPhone_6.7"
    mkdir -p "$SCREENSHOT_DIR/iPhone_6.5"
    mkdir -p "$SCREENSHOT_DIR/iPhone_5.5"
    mkdir -p "$SCREENSHOT_DIR/iPad_12.9"
    print_success "Directories created"
}

# Launch simulator with specific device
launch_simulator() {
    local device_name=$1
    print_status "Launching $device_name simulator..."
    
    # Close any running simulators
    xcrun simctl shutdown all 2>/dev/null || true
    
    # Get the device ID
    local device_id=$(xcrun simctl list devices | grep "$device_name" | grep -v "unavailable" | head -1 | awk -F'[()]' '{print $2}')
    
    if [ -z "$device_id" ]; then
        print_error "Device '$device_name' not found"
        return 1
    fi
    
    # Boot the device
    xcrun simctl boot "$device_id" 2>/dev/null || true
    
    # Open Simulator app
    open -a Simulator
    
    # Wait for boot
    sleep 5
    
    # Set status bar (iOS 17+ uses different method)
    xcrun simctl status_bar "$device_id" override \
        --time "9:41" \
        --dataNetwork wifi \
        --wifiMode active \
        --wifiBars 3 \
        --cellularMode active \
        --cellularBars 4 \
        --batteryState charged \
        --batteryLevel 100 || true
    
    print_success "Simulator ready: $device_name"
    echo "$device_id"
}

# Capture screenshot
capture_screenshot() {
    local device_id=$1
    local output_dir=$2
    local screenshot_name=$3
    local screenshot_number=$4
    
    print_status "Capturing screenshot: $screenshot_name..."
    
    # Take screenshot
    xcrun simctl io "$device_id" screenshot "$output_dir/${screenshot_number}_${screenshot_name}.png"
    
    print_success "Screenshot saved: $output_dir/${screenshot_number}_${screenshot_name}.png"
}

# Main screenshot capture flow
capture_device_screenshots() {
    local device_name=$1
    local output_dir=$2
    
    print_status "Starting screenshot capture for $device_name..."
    
    # Launch simulator
    local device_id=$(launch_simulator "$device_name")
    if [ -z "$device_id" ]; then
        return 1
    fi
    
    # Build and install app
    print_status "Building and installing app..."
    xcodebuild -project Growth.xcodeproj \
        -scheme Growth \
        -sdk iphonesimulator \
        -destination "id=$device_id" \
        -derivedDataPath ./DerivedData \
        clean build
    
    # Install the app
    local app_path=$(find ./DerivedData -name "Growth.app" -type d | head -1)
    xcrun simctl install "$device_id" "$app_path"
    
    # Launch the app
    xcrun simctl launch "$device_id" com.growthlabs.growthmethod
    sleep 3
    
    print_warning "Manual screenshots required!"
    print_status "Please capture the following screenshots in order:"
    echo ""
    echo "1. Dashboard - Main home screen with weekly calendar"
    echo "2. Methods - Growth methods library view"
    echo "3. Timer - Active timer with method instructions"
    echo "4. Progress - Progress tracking with calendar/stats"
    echo "5. AI Coach - Chat interface with coach"
    echo "6. Premium - Subscription/premium features"
    echo ""
    
    # Wait for user to position each screen
    for i in {1..6}; do
        case $i in
            1) screen_name="Dashboard" ;;
            2) screen_name="Methods" ;;
            3) screen_name="Timer" ;;
            4) screen_name="Progress" ;;
            5) screen_name="AICoach" ;;
            6) screen_name="Premium" ;;
        esac
        
        read -p "Position screen $i ($screen_name) and press Enter to capture..." 
        capture_screenshot "$device_id" "$output_dir" "$screen_name" "0$i"
    done
    
    print_success "Completed screenshots for $device_name"
}

# Validate screenshot dimensions
validate_screenshots() {
    print_status "Validating screenshot dimensions..."
    
    # iPhone 6.7" should be 1290x2796
    if [ -d "$SCREENSHOT_DIR/iPhone_6.7" ]; then
        for file in "$SCREENSHOT_DIR/iPhone_6.7"/*.png; do
            if [ -f "$file" ]; then
                dimensions=$(sips -g pixelWidth -g pixelHeight "$file" | awk '/pixel/ {print $2}' | tr '\n' 'x' | sed 's/x$//')
                if [ "$dimensions" != "1290x2796" ]; then
                    print_warning "Invalid dimensions for $file: $dimensions (expected 1290x2796)"
                fi
            fi
        done
    fi
    
    # iPad 12.9" should be 2048x2732
    if [ -d "$SCREENSHOT_DIR/iPad_12.9" ]; then
        for file in "$SCREENSHOT_DIR/iPad_12.9"/*.png; do
            if [ -f "$file" ]; then
                dimensions=$(sips -g pixelWidth -g pixelHeight "$file" | awk '/pixel/ {print $2}' | tr '\n' 'x' | sed 's/x$//')
                if [ "$dimensions" != "2048x2732" ]; then
                    print_warning "Invalid dimensions for $file: $dimensions (expected 2048x2732)"
                fi
            fi
        done
    fi
    
    print_success "Screenshot validation complete"
}

# Generate summary report
generate_report() {
    local report_file="$SCREENSHOT_DIR/screenshot_report.md"
    
    cat > "$report_file" << EOF
# App Store Screenshot Report

Generated: $(date)

## Screenshots Captured

### iPhone 6.7" (1290 × 2796)
$(ls -la "$SCREENSHOT_DIR/iPhone_6.7"/*.png 2>/dev/null | wc -l | tr -d ' ') screenshots

### iPad 12.9" (2048 × 2732)
$(ls -la "$SCREENSHOT_DIR/iPad_12.9"/*.png 2>/dev/null | wc -l | tr -d ' ') screenshots

## Checklist
- [ ] All screenshots have correct dimensions
- [ ] No personal information visible
- [ ] Consistent theme across screenshots
- [ ] Status bar shows 9:41 AM
- [ ] Battery at 100%
- [ ] Full signal bars

## Next Steps
1. Review all screenshots for quality
2. Add device frames if desired
3. Upload to App Store Connect
EOF
    
    print_success "Report generated: $report_file"
}

# Main execution
main() {
    print_status "🏠 App Store Screenshot Capture Tool"
    echo ""
    
    # Create directories
    create_directories
    
    # Show menu
    echo "Select device to capture screenshots:"
    echo "1. iPhone 15 Pro Max (6.7\")"
    echo "2. iPad Pro 12.9\" (6th gen)"
    echo "3. Both devices"
    echo "4. Validate existing screenshots"
    echo ""
    read -p "Enter choice (1-4): " choice
    
    case $choice in
        1)
            capture_device_screenshots "iPhone 15 Pro Max" "$SCREENSHOT_DIR/iPhone_6.7"
            ;;
        2)
            capture_device_screenshots "iPad Pro (12.9-inch) (6th generation)" "$SCREENSHOT_DIR/iPad_12.9"
            ;;
        3)
            capture_device_screenshots "iPhone 15 Pro Max" "$SCREENSHOT_DIR/iPhone_6.7"
            capture_device_screenshots "iPad Pro (12.9-inch) (6th generation)" "$SCREENSHOT_DIR/iPad_12.9"
            ;;
        4)
            validate_screenshots
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    # Generate report
    generate_report
    
    echo ""
    print_success "🎉 Screenshot capture complete!"
    print_status "Screenshots saved to: $SCREENSHOT_DIR"
}

# Run main function
main