#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Gruyère Debian Package Builder ===${NC}\n"

# Check if we're in the right directory
if [ ! -f "pyproject.toml" ]; then
    echo -e "${RED}Error: pyproject.toml not found. Run this script from the repo root.${NC}"
    exit 1
fi

# Extract version from pyproject.toml
VERSION=$(grep '^version = ' pyproject.toml 2>/dev/null | head -1 | cut -d'"' -f2)
if [ -z "$VERSION" ]; then
    # Try dynamic version from __init__.py
    VERSION=$(grep '__version__' gruyere/__init__.py 2>/dev/null | cut -d'"' -f2)
fi

if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Could not determine version${NC}"
    exit 1
fi

echo -e "${GREEN}Building gruyere v${VERSION}${NC}\n"

# Check for required tools
echo -e "${BLUE}Checking dependencies...${NC}"
for cmd in python3 uv gem; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: $cmd is not installed${NC}"
        exit 1
    fi
done

# Check if fpm is installed
if ! gem list | grep -q '^fpm'; then
    echo -e "${BLUE}Installing fpm (requires sudo)...${NC}"
    sudo gem install fpm
fi

# Clean previous builds
echo -e "${BLUE}Cleaning previous builds...${NC}"
rm -rf build dist *.deb

# Build wheel
echo -e "${BLUE}Building Python wheel...${NC}"
uv build

# Build Debian package
echo -e "${BLUE}Building Debian package...${NC}"
fpm -s python \
    -t deb \
    -n gruyere \
    -v "${VERSION}" \
    --python-bin python3 \
    --python-package-name-pep503 \
    dist/gruyere-*.whl

echo -e "${GREEN}✓ Build complete!${NC}\n"
ls -lh gruyere_*.deb

echo -e "\n${BLUE}Installation instructions:${NC}"
echo "  Local install:    sudo dpkg -i gruyere_${VERSION}_all.deb && sudo apt-get install -f"
echo "  Copy to server:   scp gruyere_${VERSION}_all.deb user@server:/tmp/"
echo "  Remote install:   ssh user@server 'sudo dpkg -i /tmp/gruyere_${VERSION}_all.deb && sudo apt-get install -f'"
