#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import readline from 'readline';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// Get __dirname equivalent in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Directories
const STAGING_DIR = path.join(__dirname, 'image-staging');
const METADATA_FILE = path.join(STAGING_DIR, 'download-metadata.json');
const ASSETS_PATH = path.join(__dirname, '..', 'Growth', 'Assets.xcassets');
const APPLIED_DIR = path.join(__dirname, 'applied-images');
const REVIEW_LOG = path.join(STAGING_DIR, 'review-log.json');

// Colors for terminal output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
};

// Load metadata
function loadMetadata() {
  if (!fs.existsSync(METADATA_FILE)) {
    console.log(`${colors.red}❌ No download metadata found. Run background-image-downloader.mjs first.${colors.reset}`);
    process.exit(1);
  }
  return JSON.parse(fs.readFileSync(METADATA_FILE, 'utf8'));
}

// Load review log
function loadReviewLog() {
  if (fs.existsSync(REVIEW_LOG)) {
    return JSON.parse(fs.readFileSync(REVIEW_LOG, 'utf8'));
  }
  return {
    reviewed: [],
    applied: [],
    skipped: [],
    deleted: []
  };
}

// Save review log
function saveReviewLog(log) {
  fs.writeFileSync(REVIEW_LOG, JSON.stringify(log, null, 2));
}

// Create readline interface
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Prompt for user input
function prompt(question) {
  return new Promise(resolve => {
    rl.question(question, resolve);
  });
}

// Open image in preview (macOS)
function openImage(filepath) {
  try {
    if (process.platform === 'darwin') {
      execSync(`open "${filepath}"`);
    } else if (process.platform === 'linux') {
      execSync(`xdg-open "${filepath}"`);
    } else {
      console.log(`${colors.yellow}⚠️ Please manually open: ${filepath}${colors.reset}`);
    }
  } catch (error) {
    console.log(`${colors.yellow}⚠️ Could not open image automatically${colors.reset}`);
  }
}

// Update Assets.xcassets
function applyImageToAssets(imageName, sourcePath) {
  const imagesetPath = path.join(ASSETS_PATH, `${imageName}.imageset`);
  
  // Create imageset directory
  if (!fs.existsSync(imagesetPath)) {
    fs.mkdirSync(imagesetPath, { recursive: true });
  }
  
  // Copy image
  const destPath = path.join(imagesetPath, `${imageName}.jpg`);
  fs.copyFileSync(sourcePath, destPath);
  
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
  
  // Copy to applied directory for record keeping
  if (!fs.existsSync(APPLIED_DIR)) {
    fs.mkdirSync(APPLIED_DIR, { recursive: true });
  }
  fs.copyFileSync(sourcePath, path.join(APPLIED_DIR, path.basename(sourcePath)));
}

// Review single image
async function reviewImage(download, reviewLog) {
  const filepath = path.join(STAGING_DIR, download.filename);
  
  // Check if file exists
  if (!fs.existsSync(filepath)) {
    console.log(`${colors.red}❌ Image file not found: ${download.filename}${colors.reset}`);
    reviewLog.deleted.push(download.imageName);
    return 'deleted';
  }
  
  // Display image info
  console.log(`\n${colors.bright}${'='.repeat(60)}${colors.reset}`);
  console.log(`${colors.cyan}📸 Image: ${colors.bright}${download.imageName}${colors.reset}`);
  console.log(`${colors.blue}Category:${colors.reset} ${download.category}`);
  console.log(`${colors.blue}Purpose:${colors.reset} ${download.description}`);
  console.log(`${colors.blue}Photographer:${colors.reset} ${download.photographer}`);
  console.log(`${colors.blue}Unsplash:${colors.reset} ${download.unsplashUrl}`);
  if (download.imageDescription) {
    console.log(`${colors.blue}Description:${colors.reset} ${download.imageDescription}`);
  }
  console.log(`${colors.blue}File:${colors.reset} ${download.filename}`);
  console.log(`${'='.repeat(60)}`);
  
  // Open image
  openImage(filepath);
  
  // Get user decision
  console.log(`\n${colors.yellow}Options:${colors.reset}`);
  console.log(`  ${colors.green}[a]${colors.reset} Apply - Add to Assets.xcassets`);
  console.log(`  ${colors.yellow}[s]${colors.reset} Skip - Review again later`);
  console.log(`  ${colors.red}[d]${colors.reset} Delete - Remove and don't use`);
  console.log(`  ${colors.cyan}[i]${colors.reset} Info - Show more details`);
  
  let decision = '';
  while (!['a', 's', 'd'].includes(decision)) {
    decision = (await prompt('\nYour choice (a/s/d/i): ')).toLowerCase();
    
    if (decision === 'i') {
      // Show file info
      const stats = fs.statSync(filepath);
      const sizeKB = Math.round(stats.size / 1024);
      console.log(`\n${colors.cyan}File Details:${colors.reset}`);
      console.log(`  Size: ${sizeKB} KB`);
      console.log(`  Downloaded: ${download.downloadedAt}`);
      console.log(`  Path: ${filepath}`);
    }
  }
  
  return decision;
}

// Main review process
async function main() {
  console.log(`${colors.bright}🎨 Image Review and Application Tool${colors.reset}\n`);
  
  // Load data
  const metadata = loadMetadata();
  const reviewLog = loadReviewLog();
  
  // Filter pending images
  const pendingImages = metadata.downloads.filter(d => 
    !reviewLog.applied.includes(d.imageName) &&
    !reviewLog.deleted.includes(d.imageName)
  );
  
  if (pendingImages.length === 0) {
    console.log(`${colors.green}✅ All images have been reviewed!${colors.reset}`);
    
    // Show summary
    console.log(`\n${colors.bright}Summary:${colors.reset}`);
    console.log(`  Applied: ${reviewLog.applied.length}`);
    console.log(`  Skipped: ${reviewLog.skipped.length}`);
    console.log(`  Deleted: ${reviewLog.deleted.length}`);
    
    if (reviewLog.skipped.length > 0) {
      const retry = await prompt(`\n${colors.yellow}Review ${reviewLog.skipped.length} skipped images? (y/n): ${colors.reset}`);
      if (retry.toLowerCase() === 'y') {
        reviewLog.skipped = [];
        saveReviewLog(reviewLog);
        console.log('\nRestarting review for skipped images...');
        main();
        return;
      }
    }
    
    rl.close();
    return;
  }
  
  // Show status
  console.log(`${colors.blue}Images to review: ${pendingImages.length}${colors.reset}`);
  console.log(`${colors.green}Already applied: ${reviewLog.applied.length}${colors.reset}`);
  if (reviewLog.skipped.length > 0) {
    console.log(`${colors.yellow}Currently skipped: ${reviewLog.skipped.length}${colors.reset}`);
  }
  
  // Review each image
  for (let i = 0; i < pendingImages.length; i++) {
    const download = pendingImages[i];
    
    // Skip if already in skip list
    if (reviewLog.skipped.includes(download.imageName)) {
      continue;
    }
    
    console.log(`\n${colors.bright}[${i + 1}/${pendingImages.length}]${colors.reset}`);
    
    const decision = await reviewImage(download, reviewLog);
    
    switch (decision) {
      case 'a':
        // Apply to assets
        try {
          const sourcePath = path.join(STAGING_DIR, download.filename);
          applyImageToAssets(download.imageName, sourcePath);
          reviewLog.applied.push(download.imageName);
          console.log(`${colors.green}✅ Applied ${download.imageName} to Assets.xcassets${colors.reset}`);
          
          // Remove from skip list if it was there
          reviewLog.skipped = reviewLog.skipped.filter(name => name !== download.imageName);
        } catch (error) {
          console.log(`${colors.red}❌ Failed to apply: ${error.message}${colors.reset}`);
        }
        break;
        
      case 's':
        // Skip for later
        if (!reviewLog.skipped.includes(download.imageName)) {
          reviewLog.skipped.push(download.imageName);
        }
        console.log(`${colors.yellow}⏭️ Skipped ${download.imageName}${colors.reset}`);
        break;
        
      case 'd':
        // Delete
        try {
          const filepath = path.join(STAGING_DIR, download.filename);
          fs.unlinkSync(filepath);
          reviewLog.deleted.push(download.imageName);
          console.log(`${colors.red}🗑️ Deleted ${download.imageName}${colors.reset}`);
          
          // Remove from skip list if it was there
          reviewLog.skipped = reviewLog.skipped.filter(name => name !== download.imageName);
        } catch (error) {
          console.log(`${colors.red}❌ Failed to delete: ${error.message}${colors.reset}`);
        }
        break;
    }
    
    // Save progress after each decision
    saveReviewLog(reviewLog);
    
    // Ask to continue
    if (i < pendingImages.length - 1) {
      const cont = await prompt(`\n${colors.cyan}Continue? (y/n): ${colors.reset}`);
      if (cont.toLowerCase() !== 'y') {
        break;
      }
    }
  }
  
  // Generate attribution file
  const appliedAttributions = metadata.downloads
    .filter(d => reviewLog.applied.includes(d.imageName))
    .map(d => ({
      imageName: d.imageName,
      unsplashId: d.unsplashId,
      photographer: d.photographer,
      photographerUrl: d.photographerUrl,
      description: d.imageDescription,
      appliedAt: new Date().toISOString()
    }));
  
  fs.writeFileSync(
    path.join(APPLIED_DIR, 'attributions.json'),
    JSON.stringify(appliedAttributions, null, 2)
  );
  
  console.log(`\n${colors.bright}Review session complete!${colors.reset}`);
  console.log(`Applied: ${reviewLog.applied.length}`);
  console.log(`Skipped: ${reviewLog.skipped.length}`);
  console.log(`Deleted: ${reviewLog.deleted.length}`);
  
  rl.close();
}

// Handle cleanup
process.on('SIGINT', () => {
  console.log(`\n${colors.yellow}Review paused. Progress saved.${colors.reset}`);
  rl.close();
  process.exit(0);
});

// Run the review process
main().catch(error => {
  console.error(`${colors.red}❌ Error: ${error.message}${colors.reset}`);
  rl.close();
  process.exit(1);
});