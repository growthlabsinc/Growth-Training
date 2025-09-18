#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// Get __dirname equivalent in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

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

// Generate @2x and @3x versions of an image
function generateImageSizes(inputPath, outputDir, baseName) {
  const ext = path.extname(inputPath);
  const nameWithoutExt = baseName || path.basename(inputPath, ext);
  
  // Paths for different sizes
  const output1x = path.join(outputDir, `${nameWithoutExt}${ext}`);
  const output2x = path.join(outputDir, `${nameWithoutExt}@2x${ext}`);
  const output3x = path.join(outputDir, `${nameWithoutExt}@3x${ext}`);
  
  try {
    // Copy original as 1x (if not already in place)
    if (inputPath !== output1x) {
      fs.copyFileSync(inputPath, output1x);
    }
    
    // Get original dimensions
    const dimensions = execSync(`identify -format "%wx%h" "${inputPath}"`, { encoding: 'utf8' }).trim();
    const [width, height] = dimensions.split('x').map(Number);
    
    // Generate @2x (150% quality to maintain sharpness)
    const width2x = Math.round(width * 2);
    const height2x = Math.round(height * 2);
    execSync(`convert "${inputPath}" -resize ${width2x}x${height2x} -quality 90 -sharpen 0x1 "${output2x}"`);
    console.log(`✅ Generated @2x: ${output2x} (${width2x}x${height2x})`);
    
    // Generate @3x (150% quality to maintain sharpness)
    const width3x = Math.round(width * 3);
    const height3x = Math.round(height * 3);
    execSync(`convert "${inputPath}" -resize ${width3x}x${height3x} -quality 90 -sharpen 0x1 "${output3x}"`);
    console.log(`✅ Generated @3x: ${output3x} (${width3x}x${height3x})`);
    
    return true;
  } catch (error) {
    console.error(`❌ Failed to generate sizes for ${inputPath}: ${error.message}`);
    return false;
  }
}

// Update Contents.json for an imageset
function updateContentsJson(imagesetPath, baseName, ext) {
  const contents = {
    images: [
      {
        filename: `${baseName}${ext}`,
        idiom: 'universal',
        scale: '1x'
      },
      {
        filename: `${baseName}@2x${ext}`,
        idiom: 'universal',
        scale: '2x'
      },
      {
        filename: `${baseName}@3x${ext}`,
        idiom: 'universal',
        scale: '3x'
      }
    ],
    info: {
      author: 'xcode',
      version: 1
    }
  };
  
  const contentsPath = path.join(imagesetPath, 'Contents.json');
  fs.writeFileSync(contentsPath, JSON.stringify(contents, null, 2));
  console.log(`📝 Updated Contents.json for ${baseName}`);
}

// Process downloaded images and create proper imagesets
async function processDownloadedImages() {
  const downloadedDir = path.join(__dirname, 'downloaded-images');
  const assetsPath = path.join(__dirname, '..', 'Growth', 'Assets.xcassets');
  
  if (!fs.existsSync(downloadedDir)) {
    console.error('❌ Downloaded images directory not found. Run replace-images script first.');
    return;
  }
  
  const imageFiles = fs.readdirSync(downloadedDir).filter(file => 
    file.endsWith('.jpg') || file.endsWith('.png')
  );
  
  console.log(`🔍 Found ${imageFiles.length} images to process`);
  
  for (const file of imageFiles) {
    const baseName = path.basename(file, path.extname(file));
    const imagesetPath = path.join(assetsPath, `${baseName}.imageset`);
    
    console.log(`\n📸 Processing ${baseName}...`);
    
    // Create imageset directory
    if (!fs.existsSync(imagesetPath)) {
      fs.mkdirSync(imagesetPath, { recursive: true });
    }
    
    // Generate different sizes
    const inputPath = path.join(downloadedDir, file);
    const success = generateImageSizes(inputPath, imagesetPath, baseName);
    
    if (success) {
      // Update Contents.json
      updateContentsJson(imagesetPath, baseName, path.extname(file));
    }
  }
}

// Optimize existing imagesets that already have @2x and @3x versions
async function optimizeExistingImagesets() {
  const assetsPath = path.join(__dirname, '..', 'Growth', 'Assets.xcassets');
  const imagesets = ['day4_rest_hero.imageset']; // Add other imagesets as needed
  
  console.log('\n🔧 Optimizing existing imagesets...');
  
  for (const imageset of imagesets) {
    const imagesetPath = path.join(assetsPath, imageset);
    if (!fs.existsSync(imagesetPath)) continue;
    
    const files = fs.readdirSync(imagesetPath);
    
    for (const file of files) {
      if (file.endsWith('.png') || file.endsWith('.jpg')) {
        const filePath = path.join(imagesetPath, file);
        
        // Optimize the image (reduce file size while maintaining quality)
        try {
          const tempPath = filePath + '.tmp';
          execSync(`convert "${filePath}" -quality 85 -strip "${tempPath}"`);
          
          // Check if optimization actually reduced file size
          const originalSize = fs.statSync(filePath).size;
          const optimizedSize = fs.statSync(tempPath).size;
          
          if (optimizedSize < originalSize) {
            fs.renameSync(tempPath, filePath);
            const reduction = Math.round((1 - optimizedSize / originalSize) * 100);
            console.log(`✅ Optimized ${file} (${reduction}% smaller)`);
          } else {
            fs.unlinkSync(tempPath);
            console.log(`ℹ️  ${file} is already optimized`);
          }
        } catch (error) {
          console.error(`❌ Failed to optimize ${file}: ${error.message}`);
        }
      }
    }
  }
}

// Main execution
async function main() {
  console.log('🚀 Starting iOS image optimization process...\n');
  
  if (!checkImageMagick()) {
    process.exit(1);
  }
  
  // Process downloaded images
  await processDownloadedImages();
  
  // Optimize existing imagesets
  await optimizeExistingImagesets();
  
  console.log('\n✨ Image optimization complete!');
  console.log('Remember to:');
  console.log('1. Check the generated images in Assets.xcassets');
  console.log('2. Build and run the app to ensure all images display correctly');
  console.log('3. Commit the optimized images');
}

// Run the script
main().catch(error => {
  console.error('❌ Script failed:', error);
  process.exit(1);
});