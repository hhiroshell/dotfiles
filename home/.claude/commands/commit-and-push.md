# Commit and Push

Commits staged changes and pushes to the remote current branch.

## Command

```bash
# Check if there are staged changes
if git diff --cached --quiet; then
  echo "No staged changes to commit"
  exit 1
fi

# Get current branch name
BRANCH=$(git branch --show-current)

# Generate commit message based on changes
STAGED_FILES=$(git diff --cached --name-only)
FILE_COUNT=$(echo "$STAGED_FILES" | wc -l)

if [ $FILE_COUNT -eq 1 ]; then
  # Single file - use specific message
  FILE=$(echo "$STAGED_FILES" | head -1)
  if git diff --cached --name-only --diff-filter=A | grep -q "$FILE"; then
    COMMIT_MSG="Add $FILE"
  elif git diff --cached --name-only --diff-filter=D | grep -q "$FILE"; then
    COMMIT_MSG="Remove $FILE"
  else
    COMMIT_MSG="Update $FILE"
  fi
else
  # Multiple files - use generic message with count
  COMMIT_MSG="Update $FILE_COUNT files"
fi

# Commit staged changes
git commit -m "$COMMIT_MSG"

# Push to remote current branch
git push origin "$BRANCH"

echo "Changes committed and pushed to $BRANCH with message: $COMMIT_MSG"
```

## Usage

This command will:
1. Check for staged changes
2. Generate a commit message based on the files and changes
3. Commit with the generated message
4. Push to the current branch's remote

The commit message will reflect:
- "Add [filename]" for new files
- "Remove [filename]" for deleted files
- "Update [filename]" for modified single files
- "Update X files" for multiple files

Run this when you have staged changes ready to commit and push.