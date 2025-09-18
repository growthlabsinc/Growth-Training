#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// Get __dirname equivalent in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Directories
const ASSETS_PATH = path.join(__dirname, '..', 'Growth', 'Assets.xcassets');

// Check if ImageMagick is installed
function checkImageMagick() {
  try {
    execSync('convert -version', { stdio: 'ignore' });
    return true;
  } catch {
    console.error('❌ ImageMagick is not installed.');
    console.log('To install on macOS: brew install imagemagick');
    console.log('To install on Ubuntu: sudo apt-get install imagemagick');
    return false;
  }
}

// Generate @2x and @3x versions
function generateResolutions(imagesetPath, baseName) {
  const files = fs.readdirSync(imagesetPath);
  const baseImage = files.find(f => f === `${baseName}.jpg` || f === `${baseName}.png`);
  
  if (!baseImage) {
    console.log(`⚠️  No base image found in ${baseName}.imageset`);
    return false;
  }
  
  const ext = path.extname(baseImage);
  const baseImagePath = path.join(imagesetPath, baseImage);
  
  try {
    // Get original dimensions
    const dimensions = execSync(`identify -format "%wx%h" "${baseImagePath}"`, { encoding: 'utf8' }).trim();
    const [width, height] = dimensions.split('x').map(Number);
    
    // Check if @2x and @3x already exist
    const has2x = files.some(f => f.includes('@2x'));
    const has3x = files.some(f => f.includes('@3x'));
    
    if (!has2x) {
      // Generate @2x
      const width2x = Math.round(width * 2);
      const height2x = Math.round(height * 2);
      const output2x = path.join(imagesetPath, `${baseName}@2x${ext}`);
      execSync(`convert "${baseImagePath}" -resize ${width2x}x${height2x} -quality 90 -sharpen 0x1 "${output2x}"`);
      console.log(`✅ Generated @2x for ${baseName} (${width2x}x${height2x})`);
    }
    
    if (!has3x) {
      // Generate @3x
      const width3x = Math.round(width * 3);
      const height3x = Math.round(height * 3);
      const output3x = path.join(imagesetPath, `${baseName}@3x${ext}`);
      execSync(`convert "${baseImagePath}" -resize ${width3x}x${height3x} -quality 90 -sharpen 0x1 "${output3x}"`);
      console.log(`✅ Generated @3x for ${baseName} (${width3x}x${height3x})`);
    }
    
    // Update Contents.json
    const contentsPath = path.join(imagesetPath, 'Contents.json');
    let contents;
    
    if (fs.existsSync(contentsPath)) {
      contents = JSON.parse(fs.readFileSync(contentsPath, 'utf8'));
    } else {
      contents = {
        images: [],
        info: { author: 'xcode', version: 1 }
      };
    }
    
    // Ensure all scales are represented
    const scales = ['1x', '2x', '3x'];
    scales.forEach(scale => {
      const exists = contents.images.some(img => img.scale === scale);
      if (!exists) {
        const filename = scale === '1x' ? baseImage : 
                       scale === '2x' ? `${baseName}@2x${ext}` : 
                       `${baseName}@3x${ext}`;
        contents.images.push({
          filename: filename,
          idiom: 'universal',
          scale: scale
        });
      }
    });
    
    fs.writeFileSync(contentsPath, JSON.stringify(contents, null, 2));
    
    return true;
  } catch (error) {
    console.error(`❌ Failed to generate resolutions for ${baseName}: ${error.message}`);
    return false;
  }
}

// Main function
async function main() {
  console.log('🚀 Generating iOS resolutions for applied images...\n');
  
  if (!checkImageMagick()) {
    process.exit(1);
  }
  
  // Get all imagesets
  const imagesets = fs.readdirSync(ASSETS_PATH)
    .filter(dir => dir.endsWith('.imageset'));
  
  console.log(`📦 Found ${imagesets.length} imagesets\n`);
  
  let processed = 0;
  let skipped = 0;
  
  for (const imageset of imagesets) {
    const baseName = imageset.replace('.imageset', '');
    const imagesetPath = path.join(ASSETS_PATH, imageset);
    
    // Check if this is a placeholder that might have been updated
    const placeholderNames = [
      'hero_today', 'day4_rest_hero', 'am1_0', 'am2_0', 'am2_5', 
      'angio_pumping', 'splash', 'vascular_basics', 'technique_guide',
      'progression_timeline', 'recovery_guide', 'nutrition_basics', 
      'hydration_guide'
    ];
    
    if (placeholderNames.includes(baseName)) {
      console.log(`🔍 Processing ${baseName}...`);
      if (generateResolutions(imagesetPath, baseName)) {
        processed++;
      } else {
        skipped++;
      }
    }
  }
  
  console.log(`\n✨ Complete!`);
  console.log(`   Processed: ${processed} imagesets`);
  console.log(`   Skipped: ${skipped} imagesets`);
  
  if (processed > 0) {
    console.log('\n📱 Next steps:');
    console.log('1. Open Xcode and clean build folder (Shift+Cmd+K)');
    console.log('2. Build and run the app');
    console.log('3. Verify images display correctly on different devices');
  }
}

// Run the script
main().catch(error => {
  console.error('❌ Script failed:', error);
  process.exit(1);
});