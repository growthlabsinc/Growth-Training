#!/bin/bash

# Background image download runner with scheduling

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGING_DIR="$SCRIPT_DIR/image-staging"
LOG_FILE="$STAGING_DIR/download.log"
PID_FILE="$STAGING_DIR/downloader.pid"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if process is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            return 0
        else
            rm "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Function to start the downloader
start_downloader() {
    if is_running; then
        echo -e "${YELLOW}⚠️  Downloader is already running (PID: $(cat $PID_FILE))${NC}"
        return 1
    fi
    
    echo -e "${GREEN}🚀 Starting background image downloader...${NC}"
    
    # Create staging directory
    mkdir -p "$STAGING_DIR"
    
    # Start the process in background
    nohup node "$SCRIPT_DIR/background-image-downloader.mjs" > "$STAGING_DIR/output.log" 2>&1 &
    PID=$!
    echo $PID > "$PID_FILE"
    
    echo -e "${GREEN}✅ Downloader started (PID: $PID)${NC}"
    echo -e "   Log file: $LOG_FILE"
    echo -e "   Status file: $STAGING_DIR/status.json"
    
    # Show initial status after a brief delay
    sleep 2
    show_status
}

# Function to stop the downloader
stop_downloader() {
    if ! is_running; then
        echo -e "${YELLOW}⚠️  Downloader is not running${NC}"
        return 1
    fi
    
    PID=$(cat "$PID_FILE")
    echo -e "${YELLOW}🛑 Stopping downloader (PID: $PID)...${NC}"
    
    kill $PID 2>/dev/null || true
    rm "$PID_FILE"
    
    echo -e "${GREEN}✅ Downloader stopped${NC}"
}

# Function to show status
show_status() {
    echo -e "\n${BLUE}📊 Download Status${NC}"
    echo "=================="
    
    if is_running; then
        echo -e "Status: ${GREEN}Running${NC} (PID: $(cat $PID_FILE))"
    else
        echo -e "Status: ${RED}Not running${NC}"
    fi
    
    if [ -f "$STAGING_DIR/status.json" ]; then
        echo -e "\nProgress:"
        cat "$STAGING_DIR/status.json" | grep -E '"(completed|failed|pending|remainingRequests)"' | sed 's/[",]//g' | sed 's/^/  /'
    fi
    
    if [ -f "$LOG_FILE" ]; then
        echo -e "\nRecent activity:"
        tail -5 "$LOG_FILE" | sed 's/^/  /'
    fi
    
    if [ -f "$STAGING_DIR/.unsplash-rate-limit-bg.json" ]; then
        REQUESTS=$(cat "$STAGING_DIR/.unsplash-rate-limit-bg.json" | grep -o '"requestLog":\[[^]]*\]' | grep -o '\[' | wc -l)
        echo -e "\nRate limit: Using background cache"
    fi
}

# Function to tail logs
tail_logs() {
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}❌ Log file not found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📜 Tailing download log (Ctrl+C to exit)...${NC}\n"
    tail -f "$LOG_FILE"
}

# Function to run scheduled downloads
run_scheduled() {
    echo -e "${BLUE}🕐 Running scheduled download batches...${NC}"
    echo -e "   Will run every hour if rate limit allows\n"
    
    while true; do
        if ! is_running; then
            echo -e "\n[$(date)] Starting download batch..."
            start_downloader
            
            # Wait for process to complete
            while is_running; do
                sleep 10
            done
            
            echo -e "[$(date)] Batch completed"
            
            # Check if all images are downloaded
            if [ -f "$STAGING_DIR/status.json" ]; then
                PENDING=$(cat "$STAGING_DIR/status.json" | grep '"pending"' | grep -o '[0-9]*')
                if [ "$PENDING" -eq "0" ]; then
                    echo -e "\n${GREEN}✅ All images downloaded!${NC}"
                    break
                fi
            fi
        fi
        
        # Wait 1 hour before next batch
        echo -e "\n⏰ Waiting 1 hour before next batch..."
        sleep 3600
    done
}

# Main menu
case "${1:-}" in
    start)
        start_downloader
        ;;
    stop)
        stop_downloader
        ;;
    status)
        show_status
        ;;
    logs)
        tail_logs
        ;;
    scheduled)
        run_scheduled
        ;;
    *)
        echo "Background Image Downloader"
        echo "=========================="
        echo ""
        echo "Usage: $0 {start|stop|status|logs|scheduled}"
        echo ""
        echo "Commands:"
        echo "  start     - Start the background downloader"
        echo "  stop      - Stop the background downloader"
        echo "  status    - Show current download status"
        echo "  logs      - Tail the download log"
        echo "  scheduled - Run hourly batches until complete"
        echo ""
        echo "Review downloaded images:"
        echo "  node review-and-apply-images.mjs"
        echo ""
        exit 1
        ;;
esac