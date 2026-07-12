#!/bin/bash
# Script to create GitHub Release v0.1.0
# Requires: gh CLI installed and authenticated (gh auth login)

set -e

REPO_OWNER="kaiyao28"
REPO_NAME="ByeGenoQC"
TAG="v0.1.0"
TITLE="ByeGenoQC v0.1.0"

echo "Creating GitHub Release $TAG for $REPO_OWNER/$REPO_NAME..."

# Release notes file should exist at the root
NOTES_FILE="RELEASE_v0.1.0.md"

if [ ! -f "$NOTES_FILE" ]; then
    echo "Error: $NOTES_FILE not found"
    echo "Please ensure the release notes are saved first"
    exit 1
fi

# Create the release using gh CLI
gh release create "$TAG" \
    --repo "$REPO_OWNER/$REPO_NAME" \
    --title "$TITLE" \
    --notes-file "$NOTES_FILE"

echo "✅ Release $TAG created successfully!"
echo "View it at: https://github.com/$REPO_OWNER/$REPO_NAME/releases/tag/$TAG"
