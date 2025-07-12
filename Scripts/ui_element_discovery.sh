#!/bin/bash

# Bridget UI Element Discovery Script
# Automated tool for cataloging UI components and checking HIG compliance
# Part of the UI Engineering Manifest implementation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/Documentation/UI_Analysis"
PACKAGES_DIR="$PROJECT_ROOT/Packages"
MAIN_APP_DIR="$PROJECT_ROOT/Bridget"

echo -e "${BLUE}🔍 Bridget UI Element Discovery Script${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

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

# Phase 1: Extract SwiftUI View Components
log "Phase 1: Extracting SwiftUI View Components..."

echo "# SwiftUI View Components Discovery" > "$OUTPUT_DIR/swiftui_components.md"
echo "Generated on: $(date)" >> "$OUTPUT_DIR/swiftui_components.md"
echo "" >> "$OUTPUT_DIR/swiftui_components.md"

# Find all SwiftUI View structs
log "Scanning for SwiftUI View structs..."
find "$PROJECT_ROOT" -name "*.swift" -type f | while read -r file; do
    if grep -q "struct.*View" "$file"; then
        echo "## $(basename "$file")" >> "$OUTPUT_DIR/swiftui_components.md"
        echo "**Path:** $file" >> "$OUTPUT_DIR/swiftui_components.md"
        echo "**Lines:** $(wc -l < "$file")" >> "$OUTPUT_DIR/swiftui_components.md"
        echo "" >> "$OUTPUT_DIR/swiftui_components.md"
        
        # Extract View struct names
        grep "struct.*View" "$file" | while read -r line; do
            echo "- $line" >> "$OUTPUT_DIR/swiftui_components.md"
        done
        echo "" >> "$OUTPUT_DIR/swiftui_components.md"
    fi
done

# Phase 2: Accessibility Audit
log "Phase 2: Performing Accessibility Audit..."

echo "# Accessibility Audit Report" > "$OUTPUT_DIR/accessibility_audit.md"
echo "Generated on: $(date)" >> "$OUTPUT_DIR/accessibility_audit.md"
echo "" >> "$OUTPUT_DIR/accessibility_audit.md"

# Find accessibility-related code
log "Scanning for accessibility properties..."
echo "## Accessibility Properties Found" >> "$OUTPUT_DIR/accessibility_audit.md"
echo "" >> "$OUTPUT_DIR/accessibility_audit.md"

find "$PROJECT_ROOT" -name "*.swift" -type f | while read -r file; do
    if grep -q "accessibility" "$file"; then
        echo "### $(basename "$file")" >> "$OUTPUT_DIR/accessibility_audit.md"
        echo "**Path:** $file" >> "$OUTPUT_DIR/accessibility_audit.md"
        echo "" >> "$OUTPUT_DIR/accessibility_audit.md"
        
        grep -n "accessibility" "$file" | while read -r line; do
            echo "- Line $line" >> "$OUTPUT_DIR/accessibility_audit.md"
        done
        echo "" >> "$OUTPUT_DIR/accessibility_audit.md"
    fi
done

# Phase 3: HIG Compliance Check
log "Phase 3: Checking HIG Compliance..."

echo "# HIG Compliance Report" > "$OUTPUT_DIR/hig_compliance.md"
echo "Generated on: $(date)" >> "$OUTPUT_DIR/hig_compliance.md"
echo "" >> "$OUTPUT_DIR/hig_compliance.md"

# Check for minimum touch target sizes (44x44pt)
log "Checking for minimum touch target sizes..."
echo "## Touch Target Compliance" >> "$OUTPUT_DIR/hig_compliance.md"
echo "" >> "$OUTPUT_DIR/hig_compliance.md"

find "$PROJECT_ROOT" -name "*.swift" -type f | while read -r file; do
    if grep -q "frame.*44" "$file"; then
        echo "### $(basename "$file")" >> "$OUTPUT_DIR/hig_compliance.md"
        echo "**Path:** $file" >> "$OUTPUT_DIR/hig_compliance.md"
        echo "" >> "$OUTPUT_DIR/hig_compliance.md"
        
        grep -n "frame.*44" "$file" | while read -r line; do
            echo "- Line $line" >> "$OUTPUT_DIR/hig_compliance.md"
        done
        echo "" >> "$OUTPUT_DIR/hig_compliance.md"
    fi
done

# Check for proper text sizing (17pt minimum)
log "Checking for text sizing compliance..."
echo "## Text Sizing Compliance" >> "$OUTPUT_DIR/hig_compliance.md"
echo "" >> "$OUTPUT_DIR/hig_compliance.md"

find "$PROJECT_ROOT" -name "*.swift" -type f | while read -r file; do
    if grep -q "font.*17\|font.*largeTitle\|font.*title\|font.*headline\|font.*body" "$file"; then
        echo "### $(basename "$file")" >> "$OUTPUT_DIR/hig_compliance.md"
        echo "**Path:** $file" >> "$OUTPUT_DIR/hig_compliance.md"
        echo "" >> "$OUTPUT_DIR/hig_compliance.md"
        
        grep -n "font.*17\|font.*largeTitle\|font.*title\|font.*headline\|font.*body" "$file" | while read -r line; do
            echo "- Line $line" >> "$OUTPUT_DIR/hig_compliance.md"
        done
        echo "" >> "$OUTPUT_DIR/hig_compliance.md"
    fi
done

# Phase 4: Component Classification
log "Phase 4: Classifying Components by Atomic Design..."

echo "# Atomic Design Classification" > "$OUTPUT_DIR/atomic_design.md"
echo "Generated on: $(date)" >> "$OUTPUT_DIR/atomic_design.md"
echo "" >> "$OUTPUT_DIR/atomic_design.md"

# Atoms (basic building blocks)
echo "## Atoms" >> "$OUTPUT_DIR/atomic_design.md"
echo "" >> "$OUTPUT_DIR/atomic_design.md"

# Find color usage
log "Cataloging color usage..."
echo "### Colors" >> "$OUTPUT_DIR/atomic_design.md"
find "$PROJECT_ROOT" -name "*.swift" -type f | while read -r file; do
    if grep -q "\.blue\|\.green\|\.orange\|\.red\|\.gray\|\.white\|\.black" "$file"; then
        echo "#### $(basename "$file")" >> "$OUTPUT_DIR/atomic_design.md"
        grep -o "\.blue\|\.green\|\.orange\|\.red\|\.gray\|\.white\|\.black" "$file" | sort | uniq -c | while read -r count color; do
            echo "- $color: $count occurrences" >> "$OUTPUT_DIR/atomic_design.md"
        done
        echo "" >> "$OUTPUT_DIR/atomic_design.md"
    fi
done

# Find icon usage
log "Cataloging icon usage..."
echo "### Icons" >> "$OUTPUT_DIR/atomic_design.md"
find "$PROJECT_ROOT" -name "*.swift" -type f | while read -r file; do
    if grep -q "systemName.*\"" "$file"; then
        echo "#### $(basename "$file")" >> "$OUTPUT_DIR/atomic_design.md"
        grep -o 'systemName.*"' "$file" | sed 's/systemName.*"\([^"]*\)"/\1/' | sort | uniq | while read -r icon; do
            echo "- $icon" >> "$OUTPUT_DIR/atomic_design.md"
        done
        echo "" >> "$OUTPUT_DIR/atomic_design.md"
    fi
done

# Molecules (simple combinations)
echo "## Molecules" >> "$OUTPUT_DIR/atomic_design.md"
echo "" >> "$OUTPUT_DIR/atomic_design.md"

# Find button components
log "Cataloging button components..."
echo "### Buttons" >> "$OUTPUT_DIR/atomic_design.md"
find "$PROJECT_ROOT" -name "*.swift" -type f | while read -r file; do
    if grep -q "Button\|button" "$file"; then
        echo "#### $(basename "$file")" >> "$OUTPUT_DIR/atomic_design.md"
        echo "**Path:** $file" >> "$OUTPUT_DIR/atomic_design.md"
        echo "**Lines:** $(wc -l < "$file")" >> "$OUTPUT_DIR/atomic_design.md"
        echo "" >> "$OUTPUT_DIR/atomic_design.md"
    fi
done

# Find card components
log "Cataloging card components..."
echo "### Cards" >> "$OUTPUT_DIR/atomic_design.md"
find "$PROJECT_ROOT" -name "*.swift" -type f | while read -r file; do
    if grep -q "Card\|card" "$file"; then
        echo "#### $(basename "$file")" >> "$OUTPUT_DIR/atomic_design.md"
        echo "**Path:** $file" >> "$OUTPUT_DIR/atomic_design.md"
        echo "**Lines:** $(wc -l < "$file")" >> "$OUTPUT_DIR/atomic_design.md"
        echo "" >> "$OUTPUT_DIR/atomic_design.md"
    fi
done

# Organisms (complex components)
echo "## Organisms" >> "$OUTPUT_DIR/atomic_design.md"
echo "" >> "$OUTPUT_DIR/atomic_design.md"

# Find view components (likely organisms)
log "Cataloging view components..."
echo "### Views" >> "$OUTPUT_DIR/atomic_design.md"
find "$PROJECT_ROOT" -name "*.swift" -type f | while read -r file; do
    if grep -q "struct.*View" "$file"; then
        echo "#### $(basename "$file")" >> "$OUTPUT_DIR/atomic_design.md"
        echo "**Path:** $file" >> "$OUTPUT_DIR/atomic_design.md"
        echo "**Lines:** $(wc -l < "$file")" >> "$OUTPUT_DIR/atomic_design.md"
        echo "" >> "$OUTPUT_DIR/atomic_design.md"
    fi
done

# Phase 5: Package Analysis
log "Phase 5: Analyzing Package Structure..."

echo "# Package Structure Analysis" > "$OUTPUT_DIR/package_analysis.md"
echo "Generated on: $(date)" >> "$OUTPUT_DIR/package_analysis.md"
echo "" >> "$OUTPUT_DIR/package_analysis.md"

# Analyze each package
for package in "$PACKAGES_DIR"/*; do
    if [ -d "$package" ]; then
        package_name=$(basename "$package")
        echo "## $package_name" >> "$OUTPUT_DIR/package_analysis.md"
        echo "" >> "$OUTPUT_DIR/package_analysis.md"
        
        # Count Swift files
        swift_count=$(find "$package" -name "*.swift" | wc -l)
        echo "**Swift Files:** $swift_count" >> "$OUTPUT_DIR/package_analysis.md"
        
        # List Swift files
        echo "**Files:**" >> "$OUTPUT_DIR/package_analysis.md"
        find "$package" -name "*.swift" | while read -r file; do
            echo "- $(basename "$file")" >> "$OUTPUT_DIR/package_analysis.md"
        done
        echo "" >> "$OUTPUT_DIR/package_analysis.md"
    fi
done

# Phase 6: Generate Summary Report
log "Phase 6: Generating Summary Report..."

echo "# UI Element Discovery Summary" > "$OUTPUT_DIR/summary.md"
echo "Generated on: $(date)" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

# Count total components
total_views=$(find "$PROJECT_ROOT" -name "*.swift" -type f -exec grep -l "struct.*View" {} \; | wc -l)
total_files=$(find "$PROJECT_ROOT" -name "*.swift" | wc -l)
total_packages=$(find "$PACKAGES_DIR" -maxdepth 1 -type d | wc -l)

echo "## Statistics" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"
echo "- **Total Swift Files:** $total_files" >> "$OUTPUT_DIR/summary.md"
echo "- **View Components:** $total_views" >> "$OUTPUT_DIR/summary.md"
echo "- **Packages:** $total_packages" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

# Check for potential issues
echo "## Potential Issues" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

# Check for files without accessibility
files_without_accessibility=$(find "$PROJECT_ROOT" -name "*.swift" -type f | while read -r file; do
    if ! grep -q "accessibility" "$file"; then
        echo "$file"
    fi
done | wc -l)

if [ "$files_without_accessibility" -gt 0 ]; then
    warn "Found $files_without_accessibility files without accessibility properties"
    echo "- **Files without accessibility:** $files_without_accessibility" >> "$OUTPUT_DIR/summary.md"
fi

# Check for large files (potential refactoring candidates)
find "$PROJECT_ROOT" -name "*.swift" -type f | while read -r file; do
    lines=$(wc -l < "$file")
    if [ "$lines" -gt 500 ]; then
        warn "Large file detected: $(basename "$file") ($lines lines)"
        echo "- **Large file:** $(basename "$file") ($lines lines)" >> "$OUTPUT_DIR/summary.md"
    fi
done

echo "" >> "$OUTPUT_DIR/summary.md"

# Phase 7: Generate Recommendations
log "Phase 7: Generating Recommendations..."

echo "## Recommendations" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

echo "### Immediate Actions" >> "$OUTPUT_DIR/summary.md"
echo "1. Review files without accessibility properties" >> "$OUTPUT_DIR/summary.md"
echo "2. Consider refactoring large files (>500 lines)" >> "$OUTPUT_DIR/summary.md"
echo "3. Ensure all interactive elements have proper touch targets" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

echo "### Long-term Improvements" >> "$OUTPUT_DIR/summary.md"
echo "1. Implement automated accessibility testing" >> "$OUTPUT_DIR/summary.md"
echo "2. Create component documentation templates" >> "$OUTPUT_DIR/summary.md"
echo "3. Establish HIG compliance monitoring" >> "$OUTPUT_DIR/summary.md"
echo "" >> "$OUTPUT_DIR/summary.md"

# Final summary
log "Discovery complete! Reports generated in $OUTPUT_DIR"
echo ""
echo -e "${GREEN}✅ UI Element Discovery Complete${NC}"
echo -e "${BLUE}📁 Reports saved to: $OUTPUT_DIR${NC}"
echo ""
echo "Generated reports:"
echo "- swiftui_components.md - All SwiftUI View components"
echo "- accessibility_audit.md - Accessibility properties audit"
echo "- hig_compliance.md - HIG compliance check"
echo "- atomic_design.md - Atomic design classification"
echo "- package_analysis.md - Package structure analysis"
echo "- summary.md - Summary and recommendations"
echo ""

# Optional: Open the summary report
if command -v open >/dev/null 2>&1; then
    read -p "Open summary report? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "$OUTPUT_DIR/summary.md"
    fi
fi 