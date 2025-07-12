#!/bin/bash

# Bridget Documentation Finder Tagging Script
# Adds Finder tags to documentation files for better organization

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCUMENTATION_DIR="$PROJECT_ROOT/Documentation"

echo -e "${BLUE}🏷️ Bridget Documentation Finder Tagging Script${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# Function to log with timestamp
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

# Function to log warnings
warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to log errors
error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if 'tag' command is available
if ! command -v tag >/dev/null 2>&1; then
    error "The 'tag' command is not available."
    echo "Please install it using: brew install tag"
    echo "Or download from: https://github.com/jdberry/tag"
    exit 1
fi

# Function to add tags to a file
add_tags() {
    local file="$1"
    local tags="$2"
    
    if [ -f "$file" ]; then
        tag --add "$tags" "$file"
        log "Added tags [$tags] to $(basename "$file")"
    else
        warn "File not found: $file"
    fi
}

# Function to add tags to files in a directory
add_tags_to_directory() {
    local dir="$1"
    local tags="$2"
    
    if [ -d "$dir" ]; then
        find "$dir" -name "*.md" -type f | while read -r file; do
            add_tags "$file" "$tags"
        done
    else
        warn "Directory not found: $dir"
    fi
}

log "Starting Finder tag assignment..."

# UI Engineering files
log "Tagging UI Engineering files..."
add_tags "$DOCUMENTATION_DIR/UI_Engineering/UI_ENGINEERING_MANIFEST_CHECKLIST.md" "Critical,Developer,Guide"
add_tags "$DOCUMENTATION_DIR/UI_Engineering/UI_ELEMENT_REGISTRY.md" "Critical,Developer,Reference"
add_tags "$DOCUMENTATION_DIR/UI_Engineering/UI_DISCOVERY_IMPLEMENTATION_SUMMARY.md" "High,Developer,Reference"
add_tags "$DOCUMENTATION_DIR/UI_Engineering/PHASE_1.2_READY_CHECKLIST.md" "High,Developer,Checklist"

# Analysis files
log "Tagging Analysis files..."
add_tags_to_directory "$DOCUMENTATION_DIR/Analysis/UI_Analysis" "High,Developer,Analysis"

# Accessibility files
log "Tagging Accessibility files..."
add_tags "$DOCUMENTATION_DIR/Accessibility/ACCESSIBILITY_INSPECTOR_GUIDE.md" "Critical,Developer,Guide"
add_tags "$DOCUMENTATION_DIR/Accessibility/ACCESSIBILITY_INSPECTOR_EXAMPLE.md" "High,Developer,Tutorial"
add_tags "$DOCUMENTATION_DIR/Accessibility/ACCESSIBILITY_INSPECTOR_CATALOG.md" "Medium,Developer,Reference"

# Development files
log "Tagging Development files..."
add_tags "$DOCUMENTATION_DIR/Development/SWIFTDATA_BEST_PRACTICES.md" "Critical,Developer,Guide"
add_tags "$DOCUMENTATION_DIR/Development/MODULARIZATION_GUIDE.md" "Critical,Developer,Guide"
add_tags "$DOCUMENTATION_DIR/Development/SWIFTDATA_IMPLEMENTATION_REVIEW.md" "High,Developer,Reference"
add_tags "$DOCUMENTATION_DIR/Development/SWIFTDATA_IMPLEMENTATION_TODO.md" "High,Developer,Reference"
add_tags "$DOCUMENTATION_DIR/Development/REFACTORING_DOCUMENTATION.md" "High,Developer,Reference"
add_tags "$DOCUMENTATION_DIR/Development/REFACTORING_SUMMARY.md" "High,Developer,Reference"

# Development checklist files
add_tags "$DOCUMENTATION_DIR/Development/DASHBOARD_ISSUES_FIX_PLAN.md" "Medium,Developer,Checklist"
add_tags "$DOCUMENTATION_DIR/Development/DASHBOARD_TRENDS_AND_VISUALS.md" "Medium,Developer,Checklist"
add_tags "$DOCUMENTATION_DIR/Development/BUILD_ERROR_FIX_PLAN.md" "Medium,Developer,Checklist"
add_tags "$DOCUMENTATION_DIR/Development/API_DOCUMENTATION_GENERATOR.md" "Medium,Developer,Checklist"
add_tags "$DOCUMENTATION_DIR/Development/APP_STORE_SUBMISSION.md" "Medium,Developer,Checklist"

# Development workflow files
add_tags "$DOCUMENTATION_DIR/Development/CONVERSATION_REFERENCE_GUIDE.md" "Critical,Developer,Reference"
add_tags "$DOCUMENTATION_DIR/Development/SESSION_STARTER_TEMPLATE.md" "High,Developer,Guide"

# Testing files
log "Tagging Testing files..."
add_tags "$DOCUMENTATION_DIR/Testing/TESTING_INTEGRATION_GUIDE.md" "High,QA,Guide"
add_tags "$DOCUMENTATION_DIR/Testing/MANUAL_TESTING_CHECKLIST.md" "High,QA,Guide"
add_tags "$DOCUMENTATION_DIR/Testing/BACKGROUND_PROCESSING_TEST_GUIDE.md" "Medium,QA,Tutorial"

# Features files
log "Tagging Features files..."
add_tags "$DOCUMENTATION_DIR/Features/FEATURES.md" "Critical,PM,Specification"
add_tags "$DOCUMENTATION_DIR/Features/UNIMPLEMENTED_FEATURES.md" "Critical,PM,Specification"
add_tags "$DOCUMENTATION_DIR/Features/STATISTICS_DEVELOPER_GUIDE.md" "High,Developer,Guide"
add_tags "$DOCUMENTATION_DIR/Features/MOTION_DETECTION_IMPLEMENTATION_GUIDE.md" "High,Developer,Guide"
add_tags "$DOCUMENTATION_DIR/Features/BACKGROUND_AGENTS.md" "High,Developer,Guide"
add_tags "$DOCUMENTATION_DIR/Features/STATISTICS_DOCUMENTATION.md" "Medium,Developer,Reference"
add_tags "$DOCUMENTATION_DIR/Features/MOTION_DETECTION_REAL_DEVICE_TESTING.md" "Medium,Developer,Reference"
add_tags "$DOCUMENTATION_DIR/Features/STATISTICS_USER_GUIDE.md" "Low,User,Guide"
add_tags "$DOCUMENTATION_DIR/Features/UW_TO_SPACE_NEEDLE_EXAMPLE.md" "Low,User,Guide"

# Root documentation files
log "Tagging root documentation files..."
add_tags "$DOCUMENTATION_DIR/DOCUMENTATION_INDEX.md" "Critical,Developer,Reference"
add_tags "$DOCUMENTATION_DIR/ORGANIZATION_OVERVIEW.md" "High,Developer,Reference"
add_tags "$DOCUMENTATION_DIR/FILE_TAGS_SYSTEM.md" "Medium,Developer,Reference"
add_tags "$DOCUMENTATION_DIR/README.md" "Critical,Developer,Guide"
add_tags "$DOCUMENTATION_DIR/ASSISTANT_TODO.md" "Critical,Developer,Reference"
add_tags "$DOCUMENTATION_DIR/SECURITY_VULNERABILITY_CHECKLIST.md" "Critical,Developer,Checklist"

# Scripts
log "Tagging script files..."
add_tags "$PROJECT_ROOT/Scripts/ui_element_discovery.sh" "Critical,Developer,Tool"

log "Finder tag assignment complete!"
echo ""
echo -e "${GREEN}✅ All documentation files have been tagged${NC}"
echo ""
echo "You can now use Finder's tag filtering to organize your documentation:"
echo "- Filter by 'Critical' to see must-read docs"
echo "- Filter by 'Developer' to see developer-focused content"
echo "- Filter by 'Guide' to see how-to documentation"
echo "- Filter by 'Analysis' to see automated reports"
echo ""
echo "To view tags in Finder:"
echo "1. Open the Documentation folder in Finder"
echo "2. Click the 'Tags' button in the toolbar"
echo "3. Select tags to filter files"
echo ""
echo "To remove tags:"
echo "tag --remove 'TagName' filename.md"
echo ""
echo "To list tags on a file:"
echo "tag --list filename.md" 