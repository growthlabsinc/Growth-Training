# Fix Git Lock Issues

## Problem Description
Git commands (status, add, commit) hang or timeout due to lock files and stuck processes.

## Quick Fix Steps

1. **Kill stuck git processes**
   ```bash
   ps aux | grep git | grep -v grep
   # Note the PID of stuck processes
   kill <PID>
   # Or kill all git processes:
   killall git
   ```

2. **Remove lock files**
   ```bash
   rm -f .git/index.lock
   rm -f .git/HEAD.lock
   ```

3. **Check for problematic hooks**
   ```bash
   ls -la .git/hooks/
   # Temporarily disable hooks if needed:
   mv .git/hooks/pre-commit .git/hooks/pre-commit.bak
   ```

4. **Rebuild git index if corrupted**
   ```bash
   rm -f .git/index
   git read-tree HEAD
   ```

5. **Verify and push**
   ```bash
   # Try push directly - often works even when status hangs
   git push origin main
   ```

## Advanced Fix: Using Low-Level Git Commands

When regular git commands completely fail due to persistent locks:

1. **Check if files are staged**
   ```bash
   git ls-files --stage | grep "your-file"
   ```

2. **Force commit using git internals**
   ```bash
   # Remove lock and create commit using low-level commands
   rm -f .git/index.lock
   git update-ref HEAD $(echo "Your commit message" | git commit-tree $(git write-tree) -p HEAD)
   ```

3. **Push the changes**
   ```bash
   git push origin main
   ```

This bypasses the normal git commit process and directly creates a commit object.

## Prevention

1. **Always close git GUI tools** before using command line
2. **Don't interrupt git operations** (Ctrl+C) - let them complete
3. **Check for background processes** before running git commands
4. **Use shorter timeouts** for problematic repos

## Nuclear Option
If nothing works:
```bash
# Backup your work first!
cp -r . ../backup-directory

# Then reinitialize
rm -rf .git
git init
git remote add origin <your-repo-url>
git add .
git commit -m "Reinitialize repository"
git push -f origin main
```

## Common Causes
- Multiple git processes running simultaneously
- Git GUI tools holding locks
- Interrupted git operations
- Large files causing timeouts
- Problematic git hooks
- File system permissions issues