#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import https from 'https';
import { createApi } from 'unsplash-js';
import nodeFetch from 'node-fetch';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// Get __dirname equivalent in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Unsplash API configuration
const UNSPLASH_ACCESS_KEY = '-HWsHe76Uuu83TmH78XkenJID2lytIvjgRnOtxFaATU';

// Initialize Unsplash API
const unsplash = createApi({
  accessKey: UNSPLASH_ACCESS_KEY,
  fetch: nodeFetch,
});

// Rate limiting configuration
const RATE_LIMIT = {
  maxRequests: 50,
  perHour: 3600000, // milliseconds
  requestLog: [],
  cacheFile: path.join(__dirname, '.unsplash-rate-limit.json')
};

// Load rate limit data from cache
function loadRateLimitCache() {
  try {
    if (fs.existsSync(RATE_LIMIT.cacheFile)) {
      const data = JSON.parse(fs.readFileSync(RATE_LIMIT.cacheFile, 'utf8'));
      RATE_LIMIT.requestLog = data.requestLog || [];
      console.log(`📊 Loaded rate limit cache: ${RATE_LIMIT.requestLog.length} requests in history`);
    }
  } catch (error) {
    console.log('⚠️ Could not load rate limit cache, starting fresh');
  }
}

// Save rate limit data to cache
function saveRateLimitCache() {
  try {
    fs.writeFileSync(RATE_LIMIT.cacheFile, JSON.stringify({
      requestLog: RATE_LIMIT.requestLog,
      lastUpdated: new Date().toISOString()
    }, null, 2));
  } catch (error) {
    console.error('⚠️ Could not save rate limit cache:', error.message);
  }
}

// Check if we can make a request
function canMakeRequest() {
  const now = Date.now();
  const oneHourAgo = now - RATE_LIMIT.perHour;
  
  // Filter out requests older than 1 hour
  RATE_LIMIT.requestLog = RATE_LIMIT.requestLog.filter(timestamp => timestamp > oneHourAgo);
  
  // Check if we're under the limit
  return RATE_LIMIT.requestLog.length < RATE_LIMIT.maxRequests;
}

// Get wait time until next available request
function getWaitTime() {
  if (canMakeRequest()) return 0;
  
  const now = Date.now();
  const oneHourAgo = now - RATE_LIMIT.perHour;
  const oldestRequest = RATE_LIMIT.requestLog[0];
  const waitTime = (oldestRequest + RATE_LIMIT.perHour) - now;
  
  return waitTime;
}

// Record a request
function recordRequest() {
  RATE_LIMIT.requestLog.push(Date.now());
  saveRateLimitCache();
}

// Get remaining requests in current hour
function getRemainingRequests() {
  const now = Date.now();
  const oneHourAgo = now - RATE_LIMIT.perHour;
  const recentRequests = RATE_LIMIT.requestLog.filter(timestamp => timestamp > oneHourAgo);
  return RATE_LIMIT.maxRequests - recentRequests.length;
}

// Wait for rate limit if needed
async function waitForRateLimit() {
  if (!canMakeRequest()) {
    const waitTime = getWaitTime();
    const waitMinutes = Math.ceil(waitTime / 60000);
    console.log(`⏳ Rate limit reached. Waiting ${waitMinutes} minutes...`);
    console.log(`   (You can cancel and resume later - progress is saved)`);
    
    // Show progress every minute
    for (let i = waitMinutes; i > 0; i--) {
      await new Promise(resolve => setTimeout(resolve, 60000));
      console.log(`   ${i - 1} minutes remaining...`);
    }
  }
}

// Image replacement mappings with context-aware search terms
const IMAGE_MAPPINGS = {
  // Hero images
  'hero_today': {
    searchTerms: ['fitness motivation sunrise', 'morning workout energy', 'athletic achievement'],
    description: 'Hero image for today\'s workout dashboard',
    orientation: 'landscape',
    color: null, // Will use any color
  },
  'day4_rest_hero': {
    searchTerms: ['yoga relaxation nature', 'meditation peaceful', 'rest recovery wellness'],
    description: 'Hero image for rest day experience',
    orientation: 'landscape',
    color: null,
  },
  
  // Method preview images
  'am1_0': {
    searchTerms: ['blood flow visualization', 'cardiovascular health', 'medical circulation'],
    description: 'Angion Method 1.0 preview',
    orientation: 'squarish',
    color: 'red',
  },
  'am2_0': {
    searchTerms: ['strength training close-up', 'muscle definition', 'fitness technique'],
    description: 'Angion Method 2.0 preview',
    orientation: 'squarish',
    color: null,
  },
  'am2_5': {
    searchTerms: ['advanced fitness training', 'athletic performance', 'intense workout'],
    description: 'Angion Method 2.5 preview',
    orientation: 'squarish',
    color: null,
  },
  'angio_pumping': {
    searchTerms: ['pumping exercise', 'cardiovascular workout', 'heart health fitness'],
    description: 'Angio Pumping technique preview',
    orientation: 'squarish',
    color: 'red',
  },
  
  // Educational resource placeholders
  'vascular_basics': {
    searchTerms: ['blood vessels anatomy', 'cardiovascular system', 'medical education'],
    description: 'Educational resource about vascular basics',
    orientation: 'landscape',
    color: null,
  },
  'technique_guide': {
    searchTerms: ['fitness instruction', 'exercise form guide', 'workout technique'],
    description: 'Technique guide educational resource',
    orientation: 'landscape',
    color: null,
  },
  'progression_timeline': {
    searchTerms: ['fitness progress chart', 'workout timeline', 'training progression'],
    description: 'Progression timeline educational resource',
    orientation: 'landscape',
    color: null,
  },
  'recovery_guide': {
    searchTerms: ['post workout recovery', 'muscle recovery', 'rest and recovery'],
    description: 'Recovery guide educational resource',
    orientation: 'landscape',
    color: null,
  },
  'nutrition_basics': {
    searchTerms: ['healthy nutrition', 'fitness diet', 'nutritious food'],
    description: 'Nutrition basics educational resource',
    orientation: 'landscape',
    color: null,
  },
  'hydration_guide': {
    searchTerms: ['water hydration fitness', 'drinking water athlete', 'hydration health'],
    description: 'Hydration guide educational resource',
    orientation: 'landscape',
    color: null,
  },
  
  // Splash and logo replacements
  'splash': {
    searchTerms: ['minimal fitness background', 'athletic abstract', 'health wellness gradient'],
    description: 'Splash screen background',
    orientation: 'portrait',
    color: 'green',
  },
};

// Download image from URL
async function downloadImage(url, filepath) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(filepath);
    https.get(url, (response) => {
      response.pipe(file);
      file.on('finish', () => {
        file.close();
        resolve();
      });
    }).on('error', (err) => {
      fs.unlink(filepath, () => {}); // Delete the file on error
      reject(err);
    });
  });
}

// Search for the best image on Unsplash
async function searchUnsplashImage(mapping) {
  try {
    // Try each search term until we find good results
    for (const searchTerm of mapping.searchTerms) {
      // Check rate limit before making request
      await waitForRateLimit();
      
      console.log(`🔍 Searching Unsplash for: "${searchTerm}"`);
      console.log(`   (${getRemainingRequests()} requests remaining in current hour)`);
      
      const searchParams = {
        query: searchTerm,
        perPage: 30,
        orientation: mapping.orientation,
      };
      
      if (mapping.color) {
        searchParams.color = mapping.color;
      }
      
      // Record the request
      recordRequest();
      
      const result = await unsplash.search.getPhotos(searchParams);
      
      if (result.response && result.response.results.length > 0) {
        // Filter for high-quality images
        const qualityImages = result.response.results.filter(photo => {
          return photo.likes > 10 && // Has some likes
                 photo.width >= 2000 && // High resolution
                 !photo.description?.toLowerCase().includes('nsfw'); // Safe content
        });
        
        if (qualityImages.length > 0) {
          // Sort by likes and select the best one
          qualityImages.sort((a, b) => b.likes - a.likes);
          const selectedImage = qualityImages[0];
          
          console.log(`✅ Found image: ${selectedImage.description || 'Untitled'} by ${selectedImage.user.name}`);
          console.log(`   Likes: ${selectedImage.likes}, Size: ${selectedImage.width}x${selectedImage.height}`);
          
          return {
            url: selectedImage.urls.full,
            downloadUrl: selectedImage.links.download_location,
            photographer: selectedImage.user.name,
            photographerUrl: selectedImage.user.links.html,
            description: selectedImage.description,
            id: selectedImage.id,
          };
        }
      }
    }
    
    console.log(`⚠️ No suitable images found for ${mapping.description}`);
    return null;
  } catch (error) {
    console.error(`❌ Error searching Unsplash: ${error.message}`);
    return null;
  }
}

// Track download with Unsplash API (required by their guidelines)
async function trackDownload(downloadUrl) {
  try {
    // Check rate limit before making request
    await waitForRateLimit();
    
    // Record the request
    recordRequest();
    
    await unsplash.photos.trackDownload({ downloadLocation: downloadUrl });
  } catch (error) {
    console.log(`⚠️ Failed to track download: ${error.message}`);
  }
}

// Process an individual image replacement
async function processImageReplacement(imageName, mapping, outputDir) {
  console.log(`\n📸 Processing: ${imageName}`);
  console.log(`   Description: ${mapping.description}`);
  
  const imageData = await searchUnsplashImage(mapping);
  
  if (imageData) {
    // Create output filename
    const outputPath = path.join(outputDir, `${imageName}.jpg`);
    
    // Track the download (Unsplash requirement)
    await trackDownload(imageData.downloadUrl);
    
    // Download the image
    console.log(`📥 Downloading image...`);
    await downloadImage(imageData.url, outputPath);
    
    console.log(`✅ Saved to: ${outputPath}`);
    
    // Save attribution info
    const attribution = {
      imageName,
      unsplashId: imageData.id,
      photographer: imageData.photographer,
      photographerUrl: imageData.photographerUrl,
      description: imageData.description,
      downloadedAt: new Date().toISOString(),
    };
    
    return { success: true, attribution };
  }
  
  return { success: false };
}

// Update Assets.xcassets with new images
async function updateAssetsXcassets(imageName, imagePath) {
  const assetsPath = path.join(__dirname, '..', 'Growth', 'Assets.xcassets');
  const imagesetPath = path.join(assetsPath, `${imageName}.imageset`);
  
  // Create imageset directory if it doesn't exist
  if (!fs.existsSync(imagesetPath)) {
    fs.mkdirSync(imagesetPath, { recursive: true });
  }
  
  // Copy image to imageset
  const destPath = path.join(imagesetPath, `${imageName}.jpg`);
  fs.copyFileSync(imagePath, destPath);
  
  // Create Contents.json
  const contents = {
    images: [
      {
        filename: `${imageName}.jpg`,
        idiom: 'universal',
        scale: '1x'
      },
      {
        idiom: 'universal',
        scale: '2x'
      },
      {
        idiom: 'universal',
        scale: '3x'
      }
    ],
    info: {
      author: 'xcode',
      version: 1
    }
  };
  
  fs.writeFileSync(
    path.join(imagesetPath, 'Contents.json'),
    JSON.stringify(contents, null, 2)
  );
  
  console.log(`📦 Updated Assets.xcassets for ${imageName}`);
}

// Update educational resources JSON with new URLs
async function updateEducationalResources(replacements) {
  const jsonPath = path.join(__dirname, '..', 'data', 'sample-resources.json');
  const data = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  
  // Map of placeholder names to actual resource IDs
  const resourceMappings = {
    'vascular_basics': 'vascular_health_intro',
    'technique_guide': 'technique_fundamentals',
    'progression_timeline': 'progression_guide',
    'recovery_guide': 'recovery_strategies',
    'nutrition_basics': 'nutrition_fundamentals',
    'hydration_guide': 'hydration_importance',
  };
  
  // Update visual URLs
  data.resources.forEach(resource => {
    const placeholderName = Object.keys(resourceMappings).find(
      key => resourceMappings[key] === resource.id
    );
    
    if (placeholderName && replacements[placeholderName]) {
      // For now, we'll use a local reference that the app can resolve
      resource.visual_url = `growth-resources/${placeholderName}.jpg`;
      console.log(`📝 Updated ${resource.id} visual URL`);
    }
  });
  
  // Save updated JSON
  fs.writeFileSync(jsonPath, JSON.stringify(data, null, 2));
  console.log(`✅ Updated educational resources JSON`);
}

// Main execution
async function main() {
  console.log('🚀 Starting placeholder image replacement process...\n');
  
  // Load rate limit cache
  loadRateLimitCache();
  
  // Show rate limit status
  const remaining = getRemainingRequests();
  console.log(`📊 Rate limit status: ${remaining}/${RATE_LIMIT.maxRequests} requests available`);
  
  // Create output directory
  const outputDir = path.join(__dirname, 'downloaded-images');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }
  
  // Load progress cache to resume from previous runs
  const progressFile = path.join(__dirname, '.image-replacement-progress.json');
  let completedImages = [];
  
  try {
    if (fs.existsSync(progressFile)) {
      const progress = JSON.parse(fs.readFileSync(progressFile, 'utf8'));
      completedImages = progress.completed || [];
      console.log(`📂 Resuming from previous run: ${completedImages.length} images already processed`);
    }
  } catch (error) {
    console.log('ℹ️ Starting fresh run');
  }
  
  // Track results
  const results = {
    successful: [],
    failed: [],
    attributions: [],
  };
  
  // Process each image mapping
  for (const [imageName, mapping] of Object.entries(IMAGE_MAPPINGS)) {
    // Skip if already completed in a previous run
    if (completedImages.includes(imageName)) {
      console.log(`⏭️ Skipping ${imageName} (already completed)`);
      
      // Load attribution from previous run
      try {
        const attributionPath = path.join(outputDir, 'attributions.json');
        if (fs.existsSync(attributionPath)) {
          const attributions = JSON.parse(fs.readFileSync(attributionPath, 'utf8'));
          const prevAttribution = attributions.find(a => a.imageName === imageName);
          if (prevAttribution) {
            results.attributions.push(prevAttribution);
            results.successful.push(imageName);
          }
        }
      } catch (error) {
        console.log(`⚠️ Could not load previous attribution for ${imageName}`);
      }
      
      continue;
    }
    
    const result = await processImageReplacement(imageName, mapping, outputDir);
    
    if (result.success) {
      results.successful.push(imageName);
      results.attributions.push(result.attribution);
      
      // Update progress cache
      completedImages.push(imageName);
      fs.writeFileSync(progressFile, JSON.stringify({
        completed: completedImages,
        lastUpdated: new Date().toISOString()
      }, null, 2));
      
      // Update Assets.xcassets for app images
      if (['hero_today', 'day4_rest_hero', 'am1_0', 'am2_0', 'am2_5', 'angio_pumping', 'splash'].includes(imageName)) {
        const imagePath = path.join(outputDir, `${imageName}.jpg`);
        await updateAssetsXcassets(imageName, imagePath);
      }
    } else {
      results.failed.push(imageName);
    }
    
    // Add small delay between requests
    await new Promise(resolve => setTimeout(resolve, 500));
  }
  
  // Update educational resources JSON
  const educationalReplacements = {};
  results.successful.forEach(name => {
    if (['vascular_basics', 'technique_guide', 'progression_timeline', 'recovery_guide', 'nutrition_basics', 'hydration_guide'].includes(name)) {
      educationalReplacements[name] = true;
    }
  });
  
  if (Object.keys(educationalReplacements).length > 0) {
    await updateEducationalResources(educationalReplacements);
  }
  
  // Save attribution file
  const attributionPath = path.join(outputDir, 'attributions.json');
  fs.writeFileSync(attributionPath, JSON.stringify(results.attributions, null, 2));
  
  // Print summary
  console.log('\n📊 Summary:');
  console.log(`✅ Successfully replaced: ${results.successful.length} images`);
  console.log(`❌ Failed: ${results.failed.length} images`);
  
  if (results.failed.length > 0) {
    console.log('\nFailed images:');
    results.failed.forEach(name => console.log(`  - ${name}`));
  }
  
  console.log(`\n📄 Attribution information saved to: ${attributionPath}`);
  
  // Show final rate limit status
  const finalRemaining = getRemainingRequests();
  console.log(`\n📊 Final rate limit status: ${finalRemaining}/${RATE_LIMIT.maxRequests} requests remaining`);
  
  console.log('\n✨ Process complete! Remember to:');
  console.log('1. Review the downloaded images in scripts/downloaded-images/');
  console.log('2. Run the app to ensure all images display correctly');
  console.log('3. Commit the changes to Assets.xcassets');
  console.log('4. Keep the attributions.json file for license compliance');
  
  // Clean up progress file if all completed
  if (results.failed.length === 0) {
    try {
      fs.unlinkSync(progressFile);
      console.log('\n🧹 Cleaned up progress cache (all images processed successfully)');
    } catch (error) {
      // Ignore cleanup errors
    }
  } else {
    console.log('\n💾 Progress saved. You can re-run the script to retry failed images.');
  }
}

// Run the script
main().catch(error => {
  console.error('❌ Script failed:', error);
  process.exit(1);
});