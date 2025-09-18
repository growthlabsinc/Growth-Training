#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import { execSync } from 'child_process';

// Get __dirname equivalent in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Analyze placeholder images in the project
async function analyzePlaceholders() {
  const results = {
    assetImages: [],
    codeReferences: [],
    educationalResources: [],
    recommendations: []
  };
  
  console.log('🔍 Analyzing placeholder images in Growth app...\n');
  
  // 1. Check Assets.xcassets
  console.log('📦 Checking Assets.xcassets...');
  const assetsPath = path.join(__dirname, '..', 'Growth', 'Assets.xcassets');
  
  if (fs.existsSync(assetsPath)) {
    const imagesets = fs.readdirSync(assetsPath).filter(dir => dir.endsWith('.imageset'));
    
    for (const imageset of imagesets) {
      const imagesetPath = path.join(assetsPath, imageset);
      const baseName = imageset.replace('.imageset', '');
      
      // Check for potential placeholder names
      const placeholderKeywords = ['hero', 'placeholder', 'dummy', 'sample', 'temp', 'am1_0', 'am2_0', 'am2_5', 'angio_pumping'];
      const isLikelyPlaceholder = placeholderKeywords.some(keyword => 
        baseName.toLowerCase().includes(keyword)
      );
      
      if (isLikelyPlaceholder) {
        const files = fs.readdirSync(imagesetPath).filter(f => 
          f.endsWith('.png') || f.endsWith('.jpg') || f.endsWith('.jpeg')
        );
        
        const imageInfo = {
          name: baseName,
          path: imagesetPath,
          files: files,
          hasMultipleResolutions: files.some(f => f.includes('@2x')) && files.some(f => f.includes('@3x'))
        };
        
        // Try to get image dimensions
        if (files.length > 0) {
          const firstImage = files.find(f => !f.includes('@'));
          if (firstImage) {
            try {
              const imagePath = path.join(imagesetPath, firstImage);
              const dimensions = execSync(`identify -format "%wx%h" "${imagePath}" 2>/dev/null`, { 
                encoding: 'utf8',
                stdio: ['pipe', 'pipe', 'ignore']
              }).trim();
              imageInfo.dimensions = dimensions;
            } catch {
              imageInfo.dimensions = 'unknown';
            }
          }
        }
        
        results.assetImages.push(imageInfo);
      }
    }
  }
  
  // 2. Check code references
  console.log('\n📝 Checking code references...');
  try {
    // Search for image references in Swift files
    const grepCommand = `grep -r "Image(" --include="*.swift" "${path.join(__dirname, '..')}" | grep -E "(hero|placeholder|dummy|Logo)" || true`;
    const codeRefs = execSync(grepCommand, { encoding: 'utf8' });
    
    if (codeRefs) {
      const lines = codeRefs.split('\n').filter(line => line.trim());
      lines.forEach(line => {
        const match = line.match(/Image\("([^"]+)"/);
        if (match) {
          results.codeReferences.push({
            imageName: match[1],
            file: line.split(':')[0].replace(path.join(__dirname, '..') + '/', ''),
            context: line.substring(line.indexOf('Image('))
          });
        }
      });
    }
  } catch (error) {
    console.log('  (grep not available or no matches found)');
  }
  
  // 3. Check educational resources
  console.log('\n📚 Checking educational resources...');
  const resourcesPath = path.join(__dirname, '..', 'data', 'sample-resources.json');
  if (fs.existsSync(resourcesPath)) {
    const resourceData = JSON.parse(fs.readFileSync(resourcesPath, 'utf8'));
    
    resourceData.resources.forEach(resource => {
      if (resource.visual_url && resource.visual_url.includes('example.com')) {
        results.educationalResources.push({
          id: resource.id,
          title: resource.title,
          placeholderUrl: resource.visual_url
        });
      }
    });
  }
  
  // 4. Generate recommendations
  console.log('\n🎯 Generating recommendations...');
  
  // Asset images recommendations
  results.assetImages.forEach(image => {
    if (!image.hasMultipleResolutions) {
      results.recommendations.push({
        type: 'optimization',
        image: image.name,
        message: `Missing @2x/@3x versions - run optimization script after replacement`
      });
    }
  });
  
  // Educational resources recommendations
  if (results.educationalResources.length > 0) {
    results.recommendations.push({
      type: 'resources',
      message: `${results.educationalResources.length} educational resources need real image URLs`
    });
  }
  
  // Code reference recommendations
  const logoReferences = results.codeReferences.filter(ref => ref.imageName === 'Logo');
  if (logoReferences.length > 0) {
    results.recommendations.push({
      type: 'fallback',
      message: `Logo image used as fallback in ${logoReferences.length} places - consider dedicated placeholder`
    });
  }
  
  return results;
}

// Generate markdown report
function generateReport(analysis) {
  let report = '# Placeholder Image Analysis Report\n\n';
  report += `Generated: ${new Date().toLocaleString()}\n\n`;
  
  // Summary
  report += '## Summary\n\n';
  report += `- **Asset Images Found**: ${analysis.assetImages.length}\n`;
  report += `- **Code References**: ${analysis.codeReferences.length}\n`;
  report += `- **Educational Resources**: ${analysis.educationalResources.length}\n`;
  report += `- **Recommendations**: ${analysis.recommendations.length}\n\n`;
  
  // Asset Images
  report += '## Asset Images (Potential Placeholders)\n\n';
  if (analysis.assetImages.length > 0) {
    report += '| Image Name | Dimensions | Has @2x/@3x | Status |\n';
    report += '|------------|------------|-------------|--------|\n';
    analysis.assetImages.forEach(image => {
      const status = image.hasMultipleResolutions ? '✅ Complete' : '⚠️ Needs optimization';
      report += `| ${image.name} | ${image.dimensions || 'N/A'} | ${image.hasMultipleResolutions ? 'Yes' : 'No'} | ${status} |\n`;
    });
  } else {
    report += 'No potential placeholder images found in Assets.xcassets.\n';
  }
  
  // Code References
  report += '\n## Code References\n\n';
  if (analysis.codeReferences.length > 0) {
    const groupedRefs = {};
    analysis.codeReferences.forEach(ref => {
      if (!groupedRefs[ref.imageName]) {
        groupedRefs[ref.imageName] = [];
      }
      groupedRefs[ref.imageName].push(ref);
    });
    
    Object.entries(groupedRefs).forEach(([imageName, refs]) => {
      report += `### ${imageName} (${refs.length} references)\n\n`;
      refs.forEach(ref => {
        report += `- **${ref.file}**: \`${ref.context}\`\n`;
      });
      report += '\n';
    });
  } else {
    report += 'No image references found in code.\n';
  }
  
  // Educational Resources
  report += '\n## Educational Resources with Placeholder URLs\n\n';
  if (analysis.educationalResources.length > 0) {
    report += '| Resource ID | Title | Placeholder URL |\n';
    report += '|-------------|-------|----------------|\n';
    analysis.educationalResources.forEach(resource => {
      report += `| ${resource.id} | ${resource.title} | ${resource.placeholderUrl} |\n`;
    });
  } else {
    report += 'No placeholder URLs found in educational resources.\n';
  }
  
  // Recommendations
  report += '\n## Recommendations\n\n';
  if (analysis.recommendations.length > 0) {
    analysis.recommendations.forEach((rec, index) => {
      report += `${index + 1}. **${rec.type.toUpperCase()}**: ${rec.message}\n`;
      if (rec.image) {
        report += `   - Image: ${rec.image}\n`;
      }
    });
  } else {
    report += 'No specific recommendations. All images appear to be properly set up.\n';
  }
  
  // Next Steps
  report += '\n## Next Steps\n\n';
  report += '1. Review this report to understand current placeholder status\n';
  report += '2. Run `npm run replace-images` to replace placeholders with Unsplash images\n';
  report += '3. Run `node optimize-images-for-ios.mjs` to generate multiple resolutions\n';
  report += '4. Test the app with new images\n';
  report += '5. Commit changes to version control\n';
  
  return report;
}

// Main execution
async function main() {
  console.log('🚀 Starting placeholder image analysis...\n');
  
  try {
    const analysis = await analyzePlaceholders();
    const report = generateReport(analysis);
    
    // Save report
    const reportPath = path.join(__dirname, 'placeholder-analysis-report.md');
    fs.writeFileSync(reportPath, report);
    
    // Print summary to console
    console.log('\n📊 Analysis Complete!\n');
    console.log(`Asset Images Found: ${analysis.assetImages.length}`);
    console.log(`Code References: ${analysis.codeReferences.length}`);
    console.log(`Educational Resources: ${analysis.educationalResources.length}`);
    console.log(`Recommendations: ${analysis.recommendations.length}`);
    
    console.log(`\n📄 Full report saved to: ${reportPath}`);
    console.log('\nKey findings:');
    analysis.recommendations.forEach((rec, index) => {
      console.log(`${index + 1}. ${rec.message}`);
    });
    
  } catch (error) {
    console.error('❌ Analysis failed:', error);
    process.exit(1);
  }
}

// Run the script
main();