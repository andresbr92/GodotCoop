#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const BUNDLES_PATH = path.join(__dirname, '..', '.repomix', 'bundles.json');
const PROJECT_ROOT = path.join(__dirname, '..', 'godot-coop');

// Folders to exclude from scanning
const EXCLUDED_FOLDERS = [
  'addons',
  '.git',
  '.godot',
  'node_modules'
];

// File extensions to include
const INCLUDED_EXTENSIONS = ['.gd'];

function getAllProjectFiles(dir, baseDir = dir, files = []) {
  const items = fs.readdirSync(dir);
  
  for (const item of items) {
    const fullPath = path.join(dir, item);
    const relativePath = path.relative(baseDir, fullPath);
    const stat = fs.statSync(fullPath);
    
    if (stat.isDirectory()) {
      // Skip excluded folders
      if (EXCLUDED_FOLDERS.includes(item)) {
        continue;
      }
      getAllProjectFiles(fullPath, baseDir, files);
    } else if (stat.isFile()) {
      const ext = path.extname(item).toLowerCase();
      if (INCLUDED_EXTENSIONS.includes(ext)) {
        // Convert to repomix format: godot-coop/path/to/file.gd
        const repomixPath = 'godot-coop/' + relativePath.replace(/\\/g, '/');
        files.push(repomixPath);
      }
    }
  }
  
  return files;
}

function getAddonFiles(bundleFiles) {
  return bundleFiles.filter(f => f.startsWith('godot-coop/addons/'));
}

function updateBundles() {
  // Read current bundles
  const bundlesData = JSON.parse(fs.readFileSync(BUNDLES_PATH, 'utf8'));
  
  // Get all project .gd files (excluding addons)
  const projectFiles = getAllProjectFiles(PROJECT_ROOT);
  projectFiles.sort();
  
  console.log(`Found ${projectFiles.length} project .gd files (excluding addons)`);
  
  // Update each bundle
  for (const [bundleId, bundle] of Object.entries(bundlesData.bundles)) {
    // Keep existing addon files
    const addonFiles = getAddonFiles(bundle.files);
    
    // Combine: project files + addon files
    const newFiles = [...projectFiles, ...addonFiles];
    
    const oldCount = bundle.files.length;
    bundle.files = newFiles;
    
    console.log(`\n${bundleId} (${bundle.name}):`);
    console.log(`  Before: ${oldCount} files`);
    console.log(`  After: ${newFiles.length} files`);
    console.log(`  Project: ${projectFiles.length}, Addons: ${addonFiles.length}`);
  }
  
  // Write updated bundles
  fs.writeFileSync(BUNDLES_PATH, JSON.stringify(bundlesData, null, 2));
  console.log('\n✓ Bundles updated successfully!');
}

// Run
updateBundles();
