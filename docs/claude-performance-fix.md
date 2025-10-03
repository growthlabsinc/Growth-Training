# Claude Performance Fix - Project Too Large

## Problem
Claude was opening in the project folder but not responding. The issue was caused by the project being too large (1.7GB) with many unnecessary files that Claude was trying to index.

## Root Causes
1. **Large build artifacts**: Build logs over 15MB each
2. **Multiple node_modules directories**: Found in scripts/, functions/, and other subdirectories
3. **No comprehensive .gitignore**: Many unnecessary files were being tracked
4. **Accumulated temporary files**: Lock files, backup files, and build outputs

## Solution Applied

### 1. Updated .gitignore
Added comprehensive exclusions for:
- All node_modules directories (`**/node_modules/`)
- Build artifacts (DerivedData/, build/, *.log)
- Backup files (*.backup, *.bak)
- Large binary files (*.zip, *.tar.gz)
- Temporary files and caches
- User-specific files (.bash_history, .zshrc, etc.)

### 2. Cleaned Up Project
```bash
# Remove all node_modules directories
find . -name "node_modules" -type d -print0 | xargs -0 rm -rf

# Clean Xcode DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*

# Remove old build logs
rm -f build.log detailed_build.log full_build.log build_output.log

# Remove package lock files
find . -name "package-lock.json" -o -name "yarn.lock" | xargs rm -f
```

### 3. Result
Project size reduced significantly, allowing Claude to index and respond normally.

## Prevention
1. **Regularly clean build artifacts**: Run clean commands before opening in Claude
2. **Keep .gitignore updated**: Add new patterns as needed
3. **Use focused directories**: When possible, open Claude in specific subdirectories rather than the root
4. **Run periodic cleanup**: 
   ```bash
   # Quick cleanup script
   rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
   find . -name "node_modules" -type d -print0 | xargs -0 rm -rf
   rm -f *.log
   ```

## Quick Fix Command
If Claude becomes unresponsive again, run:
```bash
cd /Users/tradeflowj/Desktop/Growth
rm -rf ~/Library/Developer/Xcode/DerivedData/Growth-*
find . -name "node_modules" -type d -print0 | xargs -0 rm -rf
rm -f build.log detailed_build.log full_build.log build_output.log
```