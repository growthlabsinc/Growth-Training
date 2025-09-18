# Background Image Replacement Guide

This guide explains the two-stage background-friendly image replacement system that handles Unsplash's rate limits while allowing you to review images before applying them to your app.

## Overview

The system consists of two stages:
1. **Background Download** - Automatically downloads images respecting rate limits
2. **Review & Apply** - Interactively review and selectively apply images

## Stage 1: Background Download

### Quick Start

```bash
cd scripts

# Option 1: Run once (downloads up to 45 images)
./run-background-download.sh start

# Option 2: Run scheduled (hourly batches until complete)
./run-background-download.sh scheduled

# Check status anytime
./run-background-download.sh status

# View logs
./run-background-download.sh logs
```

### How It Works

- Downloads images to `scripts/image-staging/` directory
- Respects Unsplash's 50 requests/hour limit (uses 45 to be safe)
- Saves progress and can resume if interrupted
- Creates detailed logs and metadata
- Runs completely in background - no terminal needed

### Background Runner Commands

```bash
# Start downloader in background
./run-background-download.sh start

# Stop background process
./run-background-download.sh stop

# Check current status
./run-background-download.sh status

# Tail log file
./run-background-download.sh logs

# Run scheduled (every hour until complete)
./run-background-download.sh scheduled
```

### Output Files

```
image-staging/
├── *.jpg                    # Downloaded images
├── download-metadata.json   # Image metadata and attributions
├── download.log            # Detailed activity log
├── status.json             # Current progress summary
└── output.log              # Process output
```

## Stage 2: Review & Apply

### Interactive Review Process

```bash
# Start review process
npm run review-images
```

For each image, the tool will:
1. Display image information (purpose, photographer, etc.)
2. Open the image in your default viewer
3. Present options:
   - **[a] Apply** - Add to Assets.xcassets
   - **[s] Skip** - Review again later
   - **[d] Delete** - Remove and don't use
   - **[i] Info** - Show file details

### Review Features

- **Resume Support** - Stop anytime and continue later
- **Skip & Retry** - Skip images and review them in a second pass
- **Auto-Preview** - Images open automatically (macOS/Linux)
- **Progress Tracking** - See how many images remain
- **Attribution Management** - Maintains photographer credits

### After Review

Applied images are:
- Copied to `Growth/Assets.xcassets/[imagename].imageset/`
- Backed up in `scripts/applied-images/`
- Tracked in `attributions.json` for licensing

## Stage 3: Generate iOS Resolutions

After applying images, generate @2x and @3x versions:

```bash
npm run generate-resolutions
```

This will:
- Find all updated imagesets
- Generate @2x and @3x versions
- Update Contents.json files
- Optimize for iOS devices

## Complete Workflow Example

```bash
# 1. Start background download (runs until rate limit)
./run-background-download.sh start

# 2. Check status
./run-background-download.sh status

# 3. When ready, review and apply images
npm run review-images

# 4. Generate iOS resolutions
npm run generate-resolutions

# 5. Build and test in Xcode
```

## Scheduled/Unattended Operation

For fully automated downloading:

```bash
# Runs every hour until all images are downloaded
./run-background-download.sh scheduled

# Later, review all at once
npm run review-images
```

## File Structure

```
scripts/
├── image-staging/              # Downloaded images pending review
│   ├── hero_today.jpg
│   ├── download-metadata.json  # Image metadata
│   ├── download.log           # Activity log
│   ├── review-log.json        # Review decisions
│   └── status.json            # Current status
├── applied-images/            # Images added to app
│   ├── *.jpg                 # Backup of applied images
│   └── attributions.json     # License attributions
└── .unsplash-rate-limit-bg.json  # Rate limit tracking
```

## Monitoring Progress

```bash
# Quick status check
./run-background-download.sh status

# Watch logs in real-time
./run-background-download.sh logs

# Check staging directory
ls -la image-staging/

# View download summary
cat image-staging/status.json
```

## Rate Limit Management

- Uses separate rate limit cache (`.unsplash-rate-limit-bg.json`)
- Leaves 5-request buffer (45 of 50 per hour)
- Automatically stops when limit reached
- Resumes in next run or scheduled hour

## Troubleshooting

### Downloads Not Starting
```bash
# Check if already running
./run-background-download.sh status

# Check rate limit
cat image-staging/.unsplash-rate-limit-bg.json
```

### Images Not Opening in Review
- Ensure you have an image viewer installed
- On macOS: Uses Preview by default
- On Linux: Requires `xdg-open`
- Manually open from `image-staging/` if needed

### Reset Everything
```bash
# Stop any running process
./run-background-download.sh stop

# Clear staging
rm -rf image-staging/

# Clear rate limits
rm .unsplash-rate-limit-bg.json

# Start fresh
./run-background-download.sh start
```

## Best Practices

1. **Run Downloads Overnight** - Use scheduled mode for unattended operation
2. **Review in Batches** - Review all images at once for consistency
3. **Keep Attributions** - Always preserve `attributions.json` for licensing
4. **Test After Applying** - Build and run app to verify images display correctly
5. **Backup Staging** - Keep `image-staging/` until you're satisfied with selections

## Next Steps

After completing the image replacement:
1. Clean build in Xcode (Shift+Cmd+K)
2. Run app on different devices/simulators
3. Verify all images display correctly
4. Commit changes to version control
5. Include `attributions.json` in your app/docs