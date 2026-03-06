#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
EXTENSION_DIR="$PROJECT_ROOT/extension"

cd "$PROJECT_ROOT"

echo -e "${YELLOW}Checking for uncommitted changes...${NC}"
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${RED}Error: You have uncommitted changes. Please commit or stash them before packaging.${NC}"
    exit 1
fi

echo -e "${YELLOW}Cleaning up old artifacts...${NC}"
rm -rf dist
rm -f dist-*.zip

echo -e "${YELLOW}Bumping patch version...${NC}"
CURRENT_VERSION=$(grep -o '"version": "[^"]*"' "$EXTENSION_DIR/manifest.json" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"

sed -i "s/\"version\": \"${CURRENT_VERSION}\"/\"version\": \"${NEW_VERSION}\"/" "$EXTENSION_DIR/manifest.json"
echo -e "  ${CURRENT_VERSION} -> ${GREEN}${NEW_VERSION}${NC}"

echo -e "${YELLOW}Committing version bump...${NC}"
git add "$EXTENSION_DIR/manifest.json"
git commit -m "Bump extension to ${NEW_VERSION}"

echo -e "${YELLOW}Pushing...${NC}"
git push

echo -e "${YELLOW}Packaging extension...${NC}"
mkdir -p dist

EXTENSION_FILES=(
    manifest.json
    background.js
    config.js
    content.js
    logger.js
    popup.html
    popup.css
    popup.js
    styles.css
)

for f in "${EXTENSION_FILES[@]}"; do
    cp "$EXTENSION_DIR/$f" dist/
done

mkdir -p dist/icons
cp "$EXTENSION_DIR/icons/icon16.png" dist/icons/
cp "$EXTENSION_DIR/icons/icon48.png" dist/icons/
cp "$EXTENSION_DIR/icons/icon128.png" dist/icons/

TIMESTAMP=$(date +"%Y%m%d%H%M")
ZIP_NAME="dist-${TIMESTAMP}.zip"

cd dist
zip -r "../${ZIP_NAME}" . -x "*.DS_Store" -x "*__MACOSX*"
cd ..

rm -rf dist

echo ""
echo -e "${GREEN}Done!${NC} ${ZIP_NAME} (v${NEW_VERSION})"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Go to https://chrome.google.com/webstore/devconsole"
echo "  2. Upload ${ZIP_NAME}"
