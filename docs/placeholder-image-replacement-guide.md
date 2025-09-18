# Placeholder Image Replacement Guide

This guide explains the automated process for replacing placeholder images throughout the Growth app with high-quality images from Unsplash.

## Overview

The automated image replacement system:
1. Identifies all placeholder images in the app
2. Analyzes context to generate appropriate search terms
3. Searches Unsplash for suitable replacements
4. Downloads and optimizes images
5. Updates the app's assets automatically
6. Maintains proper attribution for licensing

## Prerequisites

1. **Node.js** installed (v14 or higher)
2. **ImageMagick** installed (for image optimization)
   ```bash
   # macOS
   brew install imagemagick
   
   # Ubuntu/Debian
   sudo apt-get install imagemagick
   ```

## Setup

1. Navigate to the scripts directory:
   ```bash
   cd scripts
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

## Running the Image Replacement Process

### Step 1: Replace Placeholder Images

Run the main replacement script:
```bash
npm run replace-images
```

This script will:
- Search Unsplash for appropriate images based on context
- Download high-quality images
- Update Assets.xcassets for app images
- Update educational resource URLs
- Save attribution information

### Step 2: Optimize Images for iOS

After downloading, optimize images for different screen densities:
```bash
node optimize-images-for-ios.mjs
```

This script will:
- Generate @2x and @3x versions of images
- Optimize file sizes while maintaining quality
- Update Contents.json files in imagesets

## Placeholder Image Mappings

The system replaces the following placeholder images:

### Hero Images
- **hero_today**: Dashboard hero image (fitness motivation)
- **day4_rest_hero**: Rest day hero image (relaxation/recovery)

### Method Preview Images
- **am1_0**: Angion Method 1.0 (cardiovascular focus)
- **am2_0**: Angion Method 2.0 (strength training)
- **am2_5**: Angion Method 2.5 (advanced training)
- **angio_pumping**: Angio Pumping technique

### Educational Resources
- **vascular_basics**: Vascular health education
- **technique_guide**: Exercise technique instruction
- **progression_timeline**: Training progression charts
- **recovery_guide**: Recovery strategies
- **nutrition_basics**: Nutrition fundamentals
- **hydration_guide**: Hydration importance

### UI Elements
- **splash**: Splash screen background

## Customizing Search Terms

To modify the search terms for better results, edit `replace-placeholder-images.mjs`:

```javascript
const IMAGE_MAPPINGS = {
  'hero_today': {
    searchTerms: ['your', 'custom', 'search terms'],
    description: 'Description of the image',
    orientation: 'landscape', // or 'portrait', 'squarish'
    color: 'green', // optional color filter
  },
  // ... more mappings
};
```

## Attribution and Licensing

The script automatically:
- Tracks downloads as required by Unsplash guidelines
- Saves photographer attribution in `scripts/downloaded-images/attributions.json`
- Maintains compliance with Unsplash license terms

**Important**: Keep the attributions.json file for license compliance.

## Manual Image Selection

If you're not satisfied with the automated selections:

1. Visit [Unsplash](https://unsplash.com)
2. Search for images manually
3. Download the image
4. Place it in `scripts/downloaded-images/`
5. Run the optimization script
6. Update the attribution file manually

## Rate Limiting

The script automatically handles Unsplash's 50 requests per hour limit:

### Features:
- **Automatic rate limit tracking** - Counts requests and enforces limits
- **Persistent cache** - Tracks requests across script runs
- **Progress resumption** - Can stop and resume without losing progress
- **Wait time calculation** - Shows exactly when you can continue
- **Real-time status** - Displays remaining requests during execution

### How it works:
1. Each search and download tracking counts as a request
2. The script automatically waits when limit is reached
3. Progress is saved so you can cancel and resume later
4. Request history persists for accurate rate limiting

### Manual controls:
```bash
# Check current rate limit status
cat .unsplash-rate-limit.json

# Reset rate limit cache (use with caution)
rm .unsplash-rate-limit.json

# Resume interrupted run
npm run replace-images  # Automatically resumes from last successful image

# Complete reset
./reset-image-replacement.sh
```

## Troubleshooting

### API Rate Limits
- The script automatically handles rate limits
- Shows remaining requests: "23/50 requests remaining"
- Waits automatically when limit reached
- You can cancel (Ctrl+C) and resume later

### Resuming After Interruption
- Progress is automatically saved in `.image-replacement-progress.json`
- Simply run the script again to continue where you left off
- Previously downloaded images won't be re-downloaded

### Image Quality Issues
- Adjust the quality filters in the script:
  ```javascript
  photo.likes > 10 && // Minimum likes
  photo.width >= 2000 // Minimum resolution
  ```

### Search Not Finding Results
- Try broader search terms
- Remove color filters
- Change orientation requirements

### Complete Reset
If you need to start over completely:
```bash
./reset-image-replacement.sh
```
This will:
- Clear rate limit cache
- Clear progress cache
- Optionally remove downloaded images
- Optionally remove analysis report

## Adding New Placeholders

To add new placeholder replacements:

1. Add the mapping to `IMAGE_MAPPINGS` in the script
2. Include appropriate search terms and context
3. Run the replacement process
4. Update any code references to use the new image names

## Best Practices

1. **Review Downloaded Images**: Always check the downloaded images before committing
2. **Test in App**: Build and run the app to ensure images display correctly
3. **Maintain Attributions**: Keep attribution data for all images
4. **Optimize Sizes**: Use the optimization script to ensure good performance
5. **Consider Context**: Ensure images match the app's health/fitness theme

## Educational Resource Images

For educational resources, the system updates the `data/sample-resources.json` file with new image URLs. These are referenced as:
```
growth-resources/{placeholder_name}.jpg
```

You may need to implement proper URL resolution in the app to load these images.

## Commit Checklist

After running the image replacement process:

- [ ] Review all downloaded images in `scripts/downloaded-images/`
- [ ] Check that images match the intended context
- [ ] Verify @2x and @3x versions were generated
- [ ] Test the app with new images
- [ ] Commit changes to Assets.xcassets
- [ ] Include attributions.json in the repository
- [ ] Update any hardcoded image references if needed