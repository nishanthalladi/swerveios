#!/bin/bash
set -e

echo "[CI SCRIPT] Starting post-xcodebuild versioning..."

echo "[DEBUG] CI_PRIMARY_REPOSITORY_PATH is set to: $CI_PRIMARY_REPOSITORY_PATH"

echo "[DEBUG] Contents of $CI_PRIMARY_REPOSITORY_PATH/ci_scripts:"
ls -la "$CI_PRIMARY_REPOSITORY_PATH/ci_scripts"

echo "[DEBUG] Contents of $CI_PRIMARY_REPOSITORY_PATH:"
ls -la "$CI_PRIMARY_REPOSITORY_PATH"

echo "[DEBUG] Contents of $CI_PRIMARY_REPOSITORY_PATH/swerveios:"
ls -la "$CI_PRIMARY_REPOSITORY_PATH/swerveios"

#PLIST_PATH="${CI_PRIMARY_REPOSITORY_PATH}/ci_scripts/Info.plist"
PLIST_PATH="${CI_PRIMARY_REPOSITORY_PATH}/swerveios/Info.plist"

if [ ! -f "$PLIST_PATH" ]; then
    echo "[ERROR] Info.plist not found at $PLIST_PATH"
    exit 1
fi

# Bump build number
/usr/libexec/PlistBuddy -c "Increment CFBundleVersion" "$PLIST_PATH"

# Get current version
CURRENT_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$PLIST_PATH")
IFS='.' read -r MAJOR MINOR <<< "$CURRENT_VERSION"

# Increment minor version
NEW_MINOR=$((MINOR + 1))
NEW_VERSION="${MAJOR}.${NEW_MINOR}"

/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $NEW_VERSION" "$PLIST_PATH"

echo "[CI SCRIPT] Updated version to $NEW_VERSION"

# Commit & push only if changes were made
if git diff --quiet; then
    echo "[CI SCRIPT] No changes to commit."
else
    echo "[CI SCRIPT] Committing and pushing version bump..."
    git config --global user.email "ci@swerveios.com"
    git config --global user.name "Swerve CI"

    git add "$PLIST_PATH"
    git commit -m "Auto bump to $NEW_VERSION [ci skip]"
    git push origin main
fi

echo "[CI SCRIPT] Post-xcodebuild script complete."
