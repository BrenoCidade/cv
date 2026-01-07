#!/bin/bash

# Build script for CV generation
# Usage: ./build.sh [output_dir]

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get output directory from argument or use default
OUTPUT_DIR="${1:-artifacts}"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Get absolute path to output directory
OUTPUT_DIR=$(cd "$OUTPUT_DIR" && pwd)

echo -e "${BLUE}Building CVs with RenderCV...${NC}"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Build English CV
echo -e "${BLUE}Building English CV...${NC}"
cd languages
rendercv render en.yaml
cd ..

echo -e "${GREEN}✓${NC} English CV generated"
echo ""

# Build Portuguese CV
echo -e "${BLUE}Building Portuguese CV...${NC}"
cd languages
rendercv render pt.yaml
cd ..

echo -e "${GREEN}✓${NC} Portuguese CV generated"
echo ""

# Copy artifacts
echo -e "${BLUE}Copying artifacts to output directory...${NC}"

cp languages/rendercv_output/John_Doe_CV.pdf "$OUTPUT_DIR/"
cp languages/rendercv_output/John_Doe_CV.html "$OUTPUT_DIR/"
cp languages/rendercv_output/João_Silva_CV.pdf "$OUTPUT_DIR/"
cp languages/rendercv_output/João_Silva_CV.html "$OUTPUT_DIR/"

echo -e "${GREEN}✓${NC} Artifacts copied"
echo ""

# Generate metadata
echo -e "${BLUE}Generating metadata...${NC}"
cat > "$OUTPUT_DIR/metadata.json" << EOF
{
  "build_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "git_branch": "$(git branch --show-current 2>/dev/null || echo 'unknown')",
  "user": "$(whoami)"
}
EOF

echo -e "${GREEN}✓${NC} Metadata generated: $OUTPUT_DIR/metadata.json"
echo ""

# Summary
echo -e "${GREEN}=== Build Complete ===${NC}"
echo "Generated Files:"
echo ""
ls -lh "$OUTPUT_DIR"/*.{pdf,html} "$OUTPUT_DIR"/*.json 2>/dev/null || ls -lh "$OUTPUT_DIR"
echo ""
echo "Total size: $(du -sh "$OUTPUT_DIR" | cut -f1)"
echo ""
echo -e "${YELLOW}Tip:${NC} To preview locally, run: cd $OUTPUT_DIR && python -m http.server 8000"
