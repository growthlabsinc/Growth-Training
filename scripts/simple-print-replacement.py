#!/usr/bin/env python3

"""
Simple print statement replacement script for Growth App
Replaces print() statements with Logger calls in Swift files
"""

import os
import re
import shutil
from datetime import datetime
from pathlib import Path

# Colors for terminal output
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'  # No Color

class PrintReplacer:
    def __init__(self):
        self.files_processed = 0
        self.prints_replaced = 0
        self.backup_dir = f"Growth.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
    def print_status(self, message):
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"{BLUE}[{timestamp}]{NC} {message}")
        
    def print_success(self, message):
        print(f"{GREEN}✅ {message}{NC}")
        
    def print_error(self, message):
        print(f"{RED}❌ {message}{NC}")
        
    def print_warning(self, message):
        print(f"{YELLOW}⚠️  {message}{NC}")
    
    def create_backup(self):
        """Create a backup of the Growth directory"""
        self.print_status("Creating backup...")
        shutil.copytree("Growth", self.backup_dir)
        self.print_success(f"Backup created at: {self.backup_dir}")
    
    def get_log_level(self, line, filepath):
        """Determine appropriate log level based on context"""
        line_lower = line.lower()
        
        # Error patterns
        if any(word in line_lower for word in ['error', 'fail', 'exception', 'crash', 'fatal']):
            return 'error'
        
        # Warning patterns
        if any(word in line_lower for word in ['warning', 'warn', 'caution', 'deprecated']):
            return 'warning'
        
        # Info patterns
        if any(word in line_lower for word in ['success', 'complete', 'finish', 'done', 'saved', 'loaded']):
            return 'info'
        
        # File context
        if 'Service' in filepath or 'ViewModel' in filepath:
            return 'info'
        
        # Default to debug for UI components and general use
        return 'debug'
    
    def needs_import(self, content, filepath):
        """Check if file needs Logger import"""
        # Skip if Logger is defined in this file
        if 'struct Logger' in content or 'class Logger' in content:
            return False
        
        # Skip if in Core/Utilities directory (same module as Logger)
        if 'Core/Utilities' in filepath:
            return False
            
        # Check if Foundation is already imported
        return 'import Foundation' not in content
    
    def add_import(self, lines):
        """Add Foundation import to the file"""
        # Find the last import line
        last_import_idx = -1
        for i, line in enumerate(lines):
            if line.strip().startswith('import '):
                last_import_idx = i
        
        if last_import_idx >= 0:
            # Add after last import
            lines.insert(last_import_idx + 1, 'import Foundation  // For Logger\n')
        else:
            # Find first non-comment, non-empty line
            for i, line in enumerate(lines):
                if line.strip() and not line.strip().startswith('//'):
                    lines.insert(i, 'import Foundation  // For Logger\n\n')
                    break
        
        return lines
    
    def process_file(self, filepath):
        """Process a single Swift file"""
        # Skip Logger.swift itself
        if filepath.endswith('Logger.swift'):
            return
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.splitlines(True)
            
            modified = False
            new_lines = []
            file_prints = 0
            
            # Simple print statement pattern
            print_pattern = re.compile(r'^(\s*)print\((.*)\)(.*)$')
            
            for line in lines:
                # Skip if marked as Release OK
                if '// Release OK' in line:
                    new_lines.append(line)
                    continue
                
                # Check for print statement
                match = print_pattern.match(line)
                if match and '//' not in line[:line.find('print(')]:  # Not in a comment
                    indent = match.group(1)
                    print_content = match.group(2)
                    remainder = match.group(3)
                    
                    # Determine log level
                    log_level = self.get_log_level(line, filepath)
                    
                    # Replace with Logger
                    new_line = f"{indent}Logger.{log_level}({print_content}){remainder}\n"
                    new_lines.append(new_line)
                    
                    modified = True
                    file_prints += 1
                    self.prints_replaced += 1
                else:
                    new_lines.append(line)
            
            if modified:
                # Check if we need to add import
                new_content = ''.join(new_lines)
                if self.needs_import(new_content, filepath):
                    new_lines = self.add_import(new_lines)
                
                # Write back to file
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.writelines(new_lines)
                
                self.files_processed += 1
                self.print_success(f"Processed {filepath} - Replaced {file_prints} print statements")
        
        except Exception as e:
            self.print_error(f"Error processing {filepath}: {str(e)}")
    
    def process_all_files(self):
        """Process all Swift files in the Growth directory"""
        self.print_status("Processing Swift files...")
        
        for root, dirs, files in os.walk('Growth'):
            # Skip certain directories
            dirs[:] = [d for d in dirs if d not in ['.build', 'DerivedData', 'Pods', '.swiftpm']]
            
            for file in files:
                if file.endswith('.swift'):
                    filepath = os.path.join(root, file)
                    self.process_file(filepath)
    
    def generate_report(self):
        """Generate a report of the changes"""
        report = f"""# Print Statement Replacement Report

Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Summary
- Files Processed: {self.files_processed}
- Print Statements Replaced: {self.prints_replaced}
- Backup Location: {self.backup_dir}

## Changes Made
1. Replaced `print()` with appropriate `Logger` calls
2. Added Foundation imports where needed  
3. Preserved prints marked with `// Release OK`

## Next Steps
1. Review changes: `git diff`
2. Build and test the application
3. Verify logging works correctly
4. Commit changes after verification

## Reverting Changes
To revert all changes:
```bash
rm -rf Growth
cp -r {self.backup_dir} Growth
```
"""
        
        with open('print-replacement-report.md', 'w') as f:
            f.write(report)
        
        self.print_success("Report generated at: print-replacement-report.md")
    
    def run(self):
        """Main execution"""
        self.print_status("🔄 Starting print statement replacement...")
        print()
        
        # Check prerequisites
        if not os.path.exists('Growth'):
            self.print_error("Growth directory not found. Please run from project root.")
            return 1
        
        if not os.path.exists('Growth/Core/Utilities/Logger.swift'):
            self.print_error("Logger.swift not found. Please ensure Logger utility is set up.")
            return 1
        
        # Create backup
        self.create_backup()
        
        # Process files
        self.process_all_files()
        
        # Generate report
        self.generate_report()
        
        print()
        self.print_success("🎉 Print replacement completed!")
        self.print_status(f"📊 Total files modified: {self.files_processed}")
        self.print_status(f"📝 Total prints replaced: {self.prints_replaced}")
        print()
        self.print_status("Please review the changes and test thoroughly.")
        self.print_warning("Remember to commit your changes after verification!")
        
        return 0

if __name__ == "__main__":
    replacer = PrintReplacer()
    exit(replacer.run())