#!/usr/bin/env python3

"""
Swift Error Pattern Checker
This script searches for common Swift compilation errors using pattern matching.
It's much faster than running xcodebuild and can catch most common issues.
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Tuple, Dict

# Color codes for terminal output
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'  # No Color

class SwiftErrorChecker:
    def __init__(self):
        self.errors = []
        self.warnings = []
        
        # Common error patterns
        self.error_patterns = {
            # Async/await issues
            r"No 'async' operations occur within 'await' expression": "Unnecessary await - function is not async",
            
            # Property wrapper issues
            r"\$\w+\s*==": "Cannot use $ prefix in equality comparison - use without $",
            r"if\s+\$\w+": "Cannot use $ prefix in if conditions - use without $",
            r"switch\s+\$": "Cannot use $ prefix in switch statements",
            
            # Method/property access issues - more specific patterns
            r"@Published\s+let": "@Published can only be used with var, not let",
            r"@StateObject\s+let": "@StateObject can only be used with var, not let",
            r"@ObservedObject\s+let": "@ObservedObject can only be used with var, not let",
            
            # Type issues
            r"Cannot convert value of type.*to expected": "Type conversion error",
            r"Type.*does not conform to protocol": "Protocol conformance error",
            
            # Optional handling
            r"\.unwrap\(\)": "Force unwrapping detected - use optional binding instead",
            r"!\s*\.\w+": "Force unwrapping before property access",
            
            # Missing imports
            r"Use of unresolved identifier 'Firebase'": "Missing import Firebase",
            r"Use of unresolved identifier 'SwiftUI'": "Missing import SwiftUI",
            
            # Concurrency issues
            r"@MainActor\s+func.*async": "Possible concurrency issue with @MainActor",
            r"Task\s*\{[^}]*\}(?!.*await)": "Task block without await",
        }
        
        # Warning patterns
        self.warning_patterns = {
            r"print\(": "Debug print statement found",
            r"// TODO:": "TODO comment found",
            r"// FIXME:": "FIXME comment found",
            r"force_cast": "Force cast detected",
            r"try!": "Force try detected - use do-catch instead",
            r"\bas!\s": "Force cast with 'as!' detected",
        }

    def check_file(self, filepath: Path) -> Tuple[int, int]:
        """Check a single Swift file for errors and warnings."""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')
        except Exception as e:
            print(f"{RED}Error reading {filepath}: {e}{NC}")
            return 0, 0
        
        file_errors = 0
        file_warnings = 0
        
        # Check for error patterns
        for pattern, description in self.error_patterns.items():
            for i, line in enumerate(lines, 1):
                if re.search(pattern, line):
                    self.errors.append({
                        'file': str(filepath),
                        'line': i,
                        'description': description,
                        'code': line.strip()
                    })
                    file_errors += 1
        
        # Check for warning patterns
        for pattern, description in self.warning_patterns.items():
            for i, line in enumerate(lines, 1):
                if re.search(pattern, line):
                    self.warnings.append({
                        'file': str(filepath),
                        'line': i,
                        'description': description,
                        'code': line.strip()
                    })
                    file_warnings += 1
        
        # Special checks that require multi-line analysis
        self._check_async_await_issues(filepath, lines)
        self._check_binding_issues(filepath, lines)
        
        return file_errors, file_warnings
    
    def _check_async_await_issues(self, filepath: Path, lines: List[str]):
        """Check for async/await related issues."""
        content = '\n'.join(lines)
        
        # Check for await without async context
        task_blocks = re.findall(r'Task\s*\{([^}]*)\}', content, re.DOTALL)
        for block in task_blocks:
            if 'await' not in block and re.search(r'\.\w+\(.*\)', block):
                # Might be missing await
                self.warnings.append({
                    'file': str(filepath),
                    'line': 0,
                    'description': "Task block might be missing await for async calls",
                    'code': "Task { ... }"
                })
    
    def _check_binding_issues(self, filepath: Path, lines: List[str]):
        """Check for SwiftUI binding issues."""
        for i, line in enumerate(lines, 1):
            # Check for incorrect binding usage
            if '.sheet(isPresented:' in line and '$' not in line:
                self.errors.append({
                    'file': str(filepath),
                    'line': i,
                    'description': "sheet(isPresented:) requires binding with $ prefix",
                    'code': line.strip()
                })
            
            if '.alert(isPresented:' in line and '$' not in line:
                self.errors.append({
                    'file': str(filepath),
                    'line': i,
                    'description': "alert(isPresented:) requires binding with $ prefix",
                    'code': line.strip()
                })

    def check_directory(self, directory: str):
        """Recursively check all Swift files in a directory."""
        path = Path(directory)
        swift_files = list(path.rglob("*.swift"))
        
        print(f"🔍 Checking {len(swift_files)} Swift files in {directory}")
        print("=" * 60)
        
        total_errors = 0
        total_warnings = 0
        
        for swift_file in swift_files:
            errors, warnings = self.check_file(swift_file)
            total_errors += errors
            total_warnings += warnings
            
            if errors > 0:
                print(f"{RED}❌ {swift_file.relative_to(path)}{NC} - {errors} errors")
            elif warnings > 0:
                print(f"{YELLOW}⚠️  {swift_file.relative_to(path)}{NC} - {warnings} warnings")
            else:
                print(f"{GREEN}✓{NC} {swift_file.relative_to(path)}")
        
        return total_errors, total_warnings

    def print_report(self):
        """Print detailed error and warning report."""
        print("\n" + "=" * 60)
        print("DETAILED REPORT")
        print("=" * 60)
        
        if self.errors:
            print(f"\n{RED}ERRORS ({len(self.errors)}){NC}")
            print("-" * 60)
            for error in self.errors[:10]:  # Show first 10 errors
                print(f"{RED}{error['file']}:{error['line']}{NC}")
                print(f"  {error['description']}")
                print(f"  > {error['code']}")
                print()
        
        if self.warnings:
            print(f"\n{YELLOW}WARNINGS ({len(self.warnings)}){NC}")
            print("-" * 60)
            for warning in self.warnings[:10]:  # Show first 10 warnings
                print(f"{YELLOW}{warning['file']}:{warning['line']}{NC}")
                print(f"  {warning['description']}")
                print(f"  > {warning['code']}")
                print()
        
        print("\n" + "=" * 60)
        print("SUMMARY")
        print("=" * 60)
        print(f"Total Errors: {len(self.errors)}")
        print(f"Total Warnings: {len(self.warnings)}")
        
        if len(self.errors) > 0:
            print(f"\n{RED}❌ Build would likely fail due to errors{NC}")
            return 1
        else:
            print(f"\n{GREEN}✅ No critical errors found!{NC}")
            return 0


def main():
    if len(sys.argv) > 1:
        target = sys.argv[1]
    else:
        target = "Growth"
    
    checker = SwiftErrorChecker()
    
    if os.path.isfile(target):
        # Check single file
        errors, warnings = checker.check_file(Path(target))
        checker.print_report()
    else:
        # Check directory
        checker.check_directory(target)
        checker.print_report()
    
    sys.exit(1 if checker.errors else 0)


if __name__ == "__main__":
    main()