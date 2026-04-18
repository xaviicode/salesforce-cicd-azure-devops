#!/bin/bash

# Script: generate-delta-package.sh
# Purpose: Generate package.xml with only changed components
# Usage: ./generate-delta-package.sh <base-commit> <target-commit> <output-file>

BASE_COMMIT=${1:-"HEAD~1"}
TARGET_COMMIT=${2:-"HEAD"}
OUTPUT_FILE=${3:-"manifest/package.xml"}

echo "=========================================="
echo "DELTA PACKAGE GENERATION"
echo "=========================================="
echo "Base Commit: $BASE_COMMIT"
echo "Target Commit: $TARGET_COMMIT"
echo "Output File: $OUTPUT_FILE"
echo ""

# Get list of changed files in force-app, excluding non-deployable files
CHANGED_FILES=$(git diff --name-only --diff-filter=ACMR $BASE_COMMIT $TARGET_COMMIT -- force-app/ | \
  grep -v '\.eslintrc\.json$' | \
  grep -v '\.gitignore$' | \
  grep -v '\.md$' | \
  grep -v '/\..*' | \
  grep -v '^force-app/main/default/aura/\.eslintrc\.json$' | \
  grep -v '^force-app/main/default/lwc/\.eslintrc\.json$')

if [ -z "$CHANGED_FILES" ]; then
  echo "No changes detected in force-app/"
  echo "Creating empty package.xml"
  
  cat > $OUTPUT_FILE << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <version>62.0</version>
</Package>
EOF
  
  exit 0
fi

echo "Changed files detected:"
echo "$CHANGED_FILES"
echo ""

# Initialize arrays for different metadata types
declare -A APEX_CLASSES
declare -A APEX_TRIGGERS
declare -A LWC_COMPONENTS
declare -A AURA_COMPONENTS
declare -A VF_PAGES
declare -A VF_COMPONENTS

# Parse changed files and categorize
while IFS= read -r file; do
  
  # Skip if file doesn't exist (deleted or not in working directory)
  if [ ! -f "$file" ]; then
    echo "  [Skipped - File not found] $file"
    continue
  fi
  
  # Apex Classes
  if [[ $file == force-app/main/default/classes/*.cls ]]; then
    CLASS_NAME=$(basename "$file" .cls)
    APEX_CLASSES[$CLASS_NAME]=1
    echo "  [ApexClass] $CLASS_NAME"
  fi
  
  # Apex Triggers
  if [[ $file == force-app/main/default/triggers/*.trigger ]]; then
    TRIGGER_NAME=$(basename "$file" .trigger)
    APEX_TRIGGERS[$TRIGGER_NAME]=1
    echo "  [ApexTrigger] $TRIGGER_NAME"
  fi
  
  # Lightning Web Components
  if [[ $file == force-app/main/default/lwc/* ]]; then
    LWC_NAME=$(echo "$file" | cut -d'/' -f5)
    if [ ! -z "$LWC_NAME" ]; then
      LWC_COMPONENTS[$LWC_NAME]=1
      echo "  [LightningComponentBundle] $LWC_NAME"
    fi
  fi
  
  # Aura Components
  if [[ $file == force-app/main/default/aura/* ]]; then
    AURA_NAME=$(echo "$file" | cut -d'/' -f5)
    if [ ! -z "$AURA_NAME" ]; then
      AURA_COMPONENTS[$AURA_NAME]=1
      echo "  [AuraDefinitionBundle] $AURA_NAME"
    fi
  fi
  
  # Visualforce Pages
  if [[ $file == force-app/main/default/pages/*.page ]]; then
    PAGE_NAME=$(basename "$file" .page)
    VF_PAGES[$PAGE_NAME]=1
    echo "  [ApexPage] $PAGE_NAME"
  fi
  
  # Visualforce Components
  if [[ $file == force-app/main/default/components/*.component ]]; then
    COMP_NAME=$(basename "$file" .component)
    VF_COMPONENTS[$COMP_NAME]=1
    echo "  [ApexComponent] $COMP_NAME"
  fi
  
done <<< "$CHANGED_FILES"

echo ""
echo "Generating package.xml..."

# Generate package.xml
cat > $OUTPUT_FILE << 'HEADER'
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
HEADER

# Add ApexClass
if [ ${#APEX_CLASSES[@]} -gt 0 ]; then
  echo "    <types>" >> $OUTPUT_FILE
  for class in "${!APEX_CLASSES[@]}"; do
    echo "        <members>$class</members>" >> $OUTPUT_FILE
  done
  echo "        <name>ApexClass</name>" >> $OUTPUT_FILE
  echo "    </types>" >> $OUTPUT_FILE
fi

# Add ApexTrigger
if [ ${#APEX_TRIGGERS[@]} -gt 0 ]; then
  echo "    <types>" >> $OUTPUT_FILE
  for trigger in "${!APEX_TRIGGERS[@]}"; do
    echo "        <members>$trigger</members>" >> $OUTPUT_FILE
  done
  echo "        <name>ApexTrigger</name>" >> $OUTPUT_FILE
  echo "    </types>" >> $OUTPUT_FILE
fi

# Add LightningComponentBundle
if [ ${#LWC_COMPONENTS[@]} -gt 0 ]; then
  echo "    <types>" >> $OUTPUT_FILE
  for lwc in "${!LWC_COMPONENTS[@]}"; do
    echo "        <members>$lwc</members>" >> $OUTPUT_FILE
  done
  echo "        <name>LightningComponentBundle</name>" >> $OUTPUT_FILE
  echo "    </types>" >> $OUTPUT_FILE
fi

# Add AuraDefinitionBundle
if [ ${#AURA_COMPONENTS[@]} -gt 0 ]; then
  echo "    <types>" >> $OUTPUT_FILE
  for aura in "${!AURA_COMPONENTS[@]}"; do
    echo "        <members>$aura</members>" >> $OUTPUT_FILE
  done
  echo "        <name>AuraDefinitionBundle</name>" >> $OUTPUT_FILE
  echo "    </types>" >> $OUTPUT_FILE
fi

# Add ApexPage
if [ ${#VF_PAGES[@]} -gt 0 ]; then
  echo "    <types>" >> $OUTPUT_FILE
  for page in "${!VF_PAGES[@]}"; do
    echo "        <members>$page</members>" >> $OUTPUT_FILE
  done
  echo "        <name>ApexPage</name>" >> $OUTPUT_FILE
  echo "    </types>" >> $OUTPUT_FILE
fi

# Add ApexComponent
if [ ${#VF_COMPONENTS[@]} -gt 0 ]; then
  echo "    <types>" >> $OUTPUT_FILE
  for comp in "${!VF_COMPONENTS[@]}"; do
    echo "        <members>$comp</members>" >> $OUTPUT_FILE
  done
  echo "        <name>ApexComponent</name>" >> $OUTPUT_FILE
  echo "    </types>" >> $OUTPUT_FILE
fi

# Close package.xml
echo "    <version>62.0</version>" >> $OUTPUT_FILE
echo "</Package>" >> $OUTPUT_FILE

echo ""
echo "package.xml generated successfully at: $OUTPUT_FILE"
echo ""
echo "Package contents:"
cat $OUTPUT_FILE
