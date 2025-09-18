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
  maxRequests: 45, // Leave 5 request buffer for safety
  perHour: 3600000, // milliseconds
  requestLog: [],
  cacheFile: path.join(__dirname, '.unsplash-rate-limit-bg.json')
};

// Directories
const STAGING_DIR = path.join(__dirname, 'image-staging');
const METADATA_FILE = path.join(STAGING_DIR, 'download-metadata.json');

// Image replacement mappings
const IMAGE_MAPPINGS = {
  // Hero images
  'hero_today': {
    searchTerms: ['fitness motivation sunrise', 'morning workout energy', 'athletic achievement'],
    description: 'Hero image for today\'s workout dashboard',
    orientation: 'landscape',
    category: 'hero',
  },
  'day4_rest_hero': {
    searchTerms: ['yoga relaxation nature', 'meditation peaceful', 'rest recovery wellness'],
    description: 'Hero image for rest day experience',
    orientation: 'landscape',
    category: 'hero',
  },
  
  // Method preview images
  'am1_0': {
    searchTerms: ['blood flow visualization', 'cardiovascular health', 'medical circulation'],
    description: 'Angion Method 1.0 preview',
    orientation: 'squarish',
    color: 'red',
    category: 'method',
  },
  'am2_0': {
    searchTerms: ['strength training close-up', 'muscle definition', 'fitness technique'],
    description: 'Angion Method 2.0 preview',
    orientation: 'squarish',
    category: 'method',
  },
  'am2_5': {
    searchTerms: ['advanced fitness training', 'athletic performance', 'intense workout'],
    description: 'Angion Method 2.5 preview',
    orientation: 'squarish',
    category: 'method',
  },
  'angio_pumping': {
    searchTerms: ['heart pumping', 'cardio exercise', 'fitness training', 'gym workout'],
    description: 'Angio Pumping technique preview',
    orientation: 'squarish',
    color: null, // Removed red filter to get more results
    category: 'method',
  },
  
  // Educational resource placeholders
  'vascular_basics': {
    searchTerms: ['blood vessels anatomy', 'cardiovascular system', 'medical education'],
    description: 'Educational resource about vascular basics',
    orientation: 'landscape',
    category: 'educational',
  },
  'technique_guide': {
    searchTerms: ['fitness instruction', 'exercise form guide', 'workout technique'],
    description: 'Technique guide educational resource',
    orientation: 'landscape',
    category: 'educational',
  },
  'progression_timeline': {
    searchTerms: ['fitness progress chart', 'workout timeline', 'training progression'],
    description: 'Progression timeline educational resource',
    orientation: 'landscape',
    category: 'educational',
  },
  'recovery_guide': {
    searchTerms: ['post workout recovery', 'muscle recovery', 'rest and recovery'],
    description: 'Recovery guide educational resource',
    orientation: 'landscape',
    category: 'educational',
  },
  'nutrition_basics': {
    searchTerms: ['healthy nutrition', 'fitness diet', 'nutritious food'],
    description: 'Nutrition basics educational resource',
    orientation: 'landscape',
    category: 'educational',
  },
  'hydration_guide': {
    searchTerms: ['water hydration fitness', 'drinking water athlete', 'hydration health'],
    description: 'Hydration guide educational resource',
    orientation: 'landscape',
    category: 'educational',
  },
  
  // Additional educational resource hero images - Only visible articles
  'beginners-guide-angion': {
    searchTerms: ['beginner fitness guide', 'starting workout journey', 'fitness fundamentals'],
    description: 'Beginner\'s Guide to The Angion Method: Unlocking Your Growth Potential',
    orientation: 'landscape',
    category: 'educational',
  },
  'preparing-for-angion': {
    searchTerms: ['workout preparation', 'fitness foundation', 'training readiness'],
    description: 'Preparing for Angion: Foundations for Health and Growth',
    orientation: 'landscape',
    category: 'educational',
  },
  'intermediate-angion-2-0': {
    searchTerms: ['intermediate training', 'fitness progression', 'advanced technique mastery'],
    description: 'Intermediate Angion: Mastering the Angion Method 2.0',
    orientation: 'landscape',
    category: 'educational',
  },
  'intermediate-cardiovascular-training': {
    searchTerms: ['cardio fitness training', 'heart health workout', 'cardiovascular conditioning'],
    description: 'Intermediate Angion: Cardiovascular Training for Organ Building',
    orientation: 'landscape',
    category: 'educational',
  },
  'advanced-angion-vascion': {
    searchTerms: ['elite fitness training', 'apex workout method', 'advanced muscle development'],
    description: 'Advanced Angion: The Vascion (Angion Method 3.0) – Apex of Male Enhancement',
    orientation: 'landscape',
    category: 'educational',
  },
  'angion-method-evolving': {
    searchTerms: ['fitness evolution', 'workout methodology development', 'training innovation'],
    description: 'The Angion Method – An Evolving Approach to Male Vascular Health and Growth',
    orientation: 'landscape',
    category: 'educational',
  },
  'core-mechanisms-blood-vessel-growth': {
    searchTerms: ['vascular growth science', 'blood vessel development', 'biological mechanisms'],
    description: 'The Core Mechanisms of Blood Vessel Growth: Glycocalyx, Shear Stress, and Smooth Muscles',
    orientation: 'landscape',
    category: 'educational',
  },
  'holistic-male-sexual-health': {
    searchTerms: ['holistic health approach', 'male wellness lifestyle', 'sexual health nutrition'],
    description: 'Holistic Male Sexual Health and Growth: Diet, Exercise, and Lifestyle',
    orientation: 'landscape',
    category: 'educational',
  },
  
  // Splash and logo replacements
  'splash': {
    searchTerms: ['minimal fitness background', 'athletic abstract', 'health wellness gradient'],
    description: 'Splash screen background',
    orientation: 'portrait',
    color: 'green',
    category: 'ui',
  },
};

// Load rate limit data
function loadRateLimitCache() {
  try {
    if (fs.existsSync(RATE_LIMIT.cacheFile)) {
      const data = JSON.parse(fs.readFileSync(RATE_LIMIT.cacheFile, 'utf8'));
      RATE_LIMIT.requestLog = data.requestLog || [];
    }
  } catch (error) {
    // Silent fail for background operation
  }
}

// Save rate limit data
function saveRateLimitCache() {
  try {
    fs.writeFileSync(RATE_LIMIT.cacheFile, JSON.stringify({
      requestLog: RATE_LIMIT.requestLog,
      lastUpdated: new Date().toISOString()
    }, null, 2));
  } catch (error) {
    // Silent fail for background operation
  }
}

// Check if we can make a request
function canMakeRequest() {
  const now = Date.now();
  const oneHourAgo = now - RATE_LIMIT.perHour;
  RATE_LIMIT.requestLog = RATE_LIMIT.requestLog.filter(timestamp => timestamp > oneHourAgo);
  return RATE_LIMIT.requestLog.length < RATE_LIMIT.maxRequests;
}

// Record a request
function recordRequest() {
  RATE_LIMIT.requestLog.push(Date.now());
  saveRateLimitCache();
}

// Get remaining requests
function getRemainingRequests() {
  const now = Date.now();
  const oneHourAgo = now - RATE_LIMIT.perHour;
  const recentRequests = RATE_LIMIT.requestLog.filter(timestamp => timestamp > oneHourAgo);
  return RATE_LIMIT.maxRequests - recentRequests.length;
}

// Load metadata
function loadMetadata() {
  try {
    if (fs.existsSync(METADATA_FILE)) {
      return JSON.parse(fs.readFileSync(METADATA_FILE, 'utf8'));
    }
  } catch (error) {
    // Silent fail
  }
  return {
    downloads: [],
    completed: [],
    failed: [],
    lastUpdated: null
  };
}

// Save metadata
function saveMetadata(metadata) {
  metadata.lastUpdated = new Date().toISOString();
  fs.writeFileSync(METADATA_FILE, JSON.stringify(metadata, null, 2));
}

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
      fs.unlink(filepath, () => {});
      reject(err);
    });
  });
}

// Search for image on Unsplash
async function searchUnsplashImage(mapping) {
  try {
    for (const searchTerm of mapping.searchTerms) {
      if (!canMakeRequest()) {
        return null; // Skip if rate limited
      }
      
      const searchParams = {
        query: searchTerm,
        perPage: 30,
        orientation: mapping.orientation,
      };
      
      if (mapping.color) {
        searchParams.color = mapping.color;
      }
      
      recordRequest();
      const result = await unsplash.search.getPhotos(searchParams);
      
      if (result.response && result.response.results.length > 0) {
        const qualityImages = result.response.results.filter(photo => {
          return photo.likes > 10 && photo.width >= 2000;
        });
        
        if (qualityImages.length > 0) {
          qualityImages.sort((a, b) => b.likes - a.likes);
          const selectedImage = qualityImages[0];
          
          return {
            url: selectedImage.urls.full,
            downloadUrl: selectedImage.links.download_location,
            photographer: selectedImage.user.name,
            photographerUrl: selectedImage.user.links.html,
            description: selectedImage.description,
            id: selectedImage.id,
            unsplashUrl: selectedImage.links.html,
          };
        }
      }
    }
    
    return null;
  } catch (error) {
    return null;
  }
}

// Process single image
async function processImage(imageName, mapping, metadata) {
  // Skip if already completed
  if (metadata.completed.includes(imageName)) {
    return;
  }
  
  // Skip if no requests available
  if (!canMakeRequest()) {
    return;
  }
  
  const imageData = await searchUnsplashImage(mapping);
  
  if (imageData) {
    try {
      // Track download (if we have requests left)
      if (canMakeRequest()) {
        recordRequest();
        await unsplash.photos.trackDownload({ downloadLocation: imageData.downloadUrl });
      }
      
      // Download image
      const filename = `${imageName}.jpg`;
      const filepath = path.join(STAGING_DIR, filename);
      await downloadImage(imageData.url, filepath);
      
      // Save download info
      const downloadInfo = {
        imageName,
        filename,
        category: mapping.category,
        description: mapping.description,
        photographer: imageData.photographer,
        photographerUrl: imageData.photographerUrl,
        unsplashId: imageData.id,
        unsplashUrl: imageData.unsplashUrl,
        imageDescription: imageData.description,
        downloadedAt: new Date().toISOString(),
        status: 'pending_review'
      };
      
      metadata.downloads.push(downloadInfo);
      metadata.completed.push(imageName);
      saveMetadata(metadata);
      
      // Log success to file
      const logEntry = `[${new Date().toISOString()}] SUCCESS: ${imageName} - ${imageData.description || 'No description'} by ${imageData.photographer}\n`;
      fs.appendFileSync(path.join(STAGING_DIR, 'download.log'), logEntry);
      
    } catch (error) {
      metadata.failed.push({ imageName, error: error.message, timestamp: new Date().toISOString() });
      saveMetadata(metadata);
    }
  } else {
    metadata.failed.push({ imageName, error: 'No suitable images found', timestamp: new Date().toISOString() });
    saveMetadata(metadata);
  }
}

// Main background process
async function main() {
  // Setup directories
  if (!fs.existsSync(STAGING_DIR)) {
    fs.mkdirSync(STAGING_DIR, { recursive: true });
  }
  
  // Log start
  const startLog = `\n[${new Date().toISOString()}] Background download process started\n`;
  fs.appendFileSync(path.join(STAGING_DIR, 'download.log'), startLog);
  
  // Load state
  loadRateLimitCache();
  const metadata = loadMetadata();
  
  // Process images
  for (const [imageName, mapping] of Object.entries(IMAGE_MAPPINGS)) {
    const remaining = getRemainingRequests();
    
    if (remaining < 2) {
      // Not enough requests, exit gracefully
      const exitLog = `[${new Date().toISOString()}] Exiting - Rate limit reached (${remaining} requests remaining)\n`;
      fs.appendFileSync(path.join(STAGING_DIR, 'download.log'), exitLog);
      break;
    }
    
    await processImage(imageName, mapping, metadata);
    
    // Small delay between images
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  // Final status
  const summary = {
    totalImages: Object.keys(IMAGE_MAPPINGS).length,
    completed: metadata.completed.length,
    failed: metadata.failed.length,
    pending: Object.keys(IMAGE_MAPPINGS).length - metadata.completed.length,
    remainingRequests: getRemainingRequests()
  };
  
  const summaryLog = `[${new Date().toISOString()}] Summary: ${JSON.stringify(summary)}\n`;
  fs.appendFileSync(path.join(STAGING_DIR, 'download.log'), summaryLog);
  
  // Create status file for easy checking
  fs.writeFileSync(path.join(STAGING_DIR, 'status.json'), JSON.stringify(summary, null, 2));
}

// Run the background process
main().catch(error => {
  const errorLog = `[${new Date().toISOString()}] FATAL ERROR: ${error.message}\n`;
  fs.appendFileSync(path.join(STAGING_DIR, 'download.log'), errorLog);
  process.exit(1);
});