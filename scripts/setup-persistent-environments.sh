#!/bin/bash

# ============================================================================
# SCRIPT: Setup Persistent Scratch Org Environments
# ============================================================================

set -e  # Exit on any error

echo "========================================================================"
echo "  SALESFORCE CI/CD - PERSISTENT ENVIRONMENTS SETUP"
echo "========================================================================"
echo ""
echo "This script will create 3 persistent Scratch Orgs:"
echo "  • DEV  - Development environment (30 days)"
echo "  • QA   - Quality Assurance environment (30 days)"
echo "  • UAT  - User Acceptance Testing environment (30 days)"
echo ""
echo "  • PROD - Uses your existing Developer Edition"
echo "           (xavilopez581661@agentforce.com)"
echo ""
echo "Cost: $0 - Uses free Scratch Org allocation"
echo "Maintenance: Re-run this script every 28-30 days"
echo ""
echo "========================================================================"
echo ""

# Check if Salesforce CLI is installed
if ! command -v sf &> /dev/null; then
    echo "❌ ERROR: Salesforce CLI is not installed"
    echo "   Install from: https://developer.salesforce.com/tools/salesforcecli"
    exit 1
fi

echo "✅ Salesforce CLI found: $(sf version --json | jq -r '.version' 2>/dev/null || sf version)"
echo ""

# Authenticate to Dev Hub if not already authenticated
echo "========================================================================"
echo "STEP 1: Authenticate to Dev Hub"
echo "========================================================================"
echo ""

# Check if Dev Hub is already authenticated
DEV_HUB_AUTH=$(sf org list --json 2>/dev/null | jq -r '.result.nonScratchOrgs[] | select(.isDevHub == true) | .alias' | head -1 || echo "")

if [ -z "$DEV_HUB_AUTH" ]; then
    echo "No Dev Hub authenticated. Opening browser for authentication..."
    sf org login web --set-default-dev-hub --alias DevHub
    echo "✅ Dev Hub authenticated successfully"
else
    echo "✅ Dev Hub already authenticated: $DEV_HUB_AUTH"
fi

echo ""

# Check current Scratch Org usage
echo "========================================================================"
echo "STEP 2: Check Current Scratch Org Usage"
echo "========================================================================"
echo ""

ACTIVE_SCRATCH_ORGS=$(sf org list --json 2>/dev/null | jq -r '.result.scratchOrgs | length' || echo "0")
echo "Active Scratch Orgs: $ACTIVE_SCRATCH_ORGS / 3"

if [ "$ACTIVE_SCRATCH_ORGS" -ge 3 ]; then
    echo ""
    echo "⚠️  WARNING: You have 3 active Scratch Orgs (maximum)"
    echo ""
    echo "Current Scratch Orgs:"
    sf org list --scratch-orgs
    echo ""
    echo "Would you like to delete existing Scratch Orgs? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Deleting all Scratch Orgs..."
        sf org delete scratch --all --no-prompt
        echo "✅ Scratch Orgs deleted"
    else
        echo "❌ Cannot proceed with 3 active Scratch Orgs. Exiting."
        exit 1
    fi
fi

echo ""

# Create DEV Environment
echo "========================================================================"
echo "STEP 3: Creating DEV Environment"
echo "========================================================================"
echo ""

echo "Creating DEV Scratch Org (30 days)..."
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias persistent-dev \
  --duration-days 30 \
  --set-default \
  --no-track-source

echo "✅ DEV environment created: persistent-dev"
echo ""

# Get DEV org info
DEV_USERNAME=$(sf org display --target-org persistent-dev --json | jq -r '.result.username')
DEV_INSTANCE_URL=$(sf org display --target-org persistent-dev --json | jq -r '.result.instanceUrl')
DEV_ORG_ID=$(sf org display --target-org persistent-dev --json | jq -r '.result.id')

echo "DEV Details:"
echo "  Username: $DEV_USERNAME"
echo "  Instance URL: $DEV_INSTANCE_URL"
echo "  Org ID: $DEV_ORG_ID"
echo ""

# Create QA Environment
echo "========================================================================"
echo "STEP 4: Creating QA Environment"
echo "========================================================================"
echo ""

echo "Creating QA Scratch Org (30 days)..."
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias persistent-qa \
  --duration-days 30 \
  --no-track-source

echo "✅ QA environment created: persistent-qa"
echo ""

# Get QA org info
QA_USERNAME=$(sf org display --target-org persistent-qa --json | jq -r '.result.username')
QA_INSTANCE_URL=$(sf org display --target-org persistent-qa --json | jq -r '.result.instanceUrl')
QA_ORG_ID=$(sf org display --target-org persistent-qa --json | jq -r '.result.id')

echo "QA Details:"
echo "  Username: $QA_USERNAME"
echo "  Instance URL: $QA_INSTANCE_URL"
echo "  Org ID: $QA_ORG_ID"
echo ""

# Create UAT Environment
echo "========================================================================"
echo "STEP 5: Creating UAT Environment"
echo "========================================================================"
echo ""

echo "Creating UAT Scratch Org (30 days)..."
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias persistent-uat \
  --duration-days 30 \
  --no-track-source

echo "✅ UAT environment created: persistent-uat"
echo ""

# Get UAT org info
UAT_USERNAME=$(sf org display --target-org persistent-uat --json | jq -r '.result.username')
UAT_INSTANCE_URL=$(sf org display --target-org persistent-uat --json | jq -r '.result.instanceUrl')
UAT_ORG_ID=$(sf org display --target-org persistent-uat --json | jq -r '.result.id')

echo "UAT Details:"
echo "  Username: $UAT_USERNAME"
echo "  Instance URL: $UAT_INSTANCE_URL"
echo "  Org ID: $UAT_ORG_ID"
echo ""

# PROD is existing Developer Edition
echo "========================================================================"
echo "STEP 6: PROD Environment (Existing Developer Edition)"
echo "========================================================================"
echo ""

echo "PROD uses your existing Developer Edition:"
echo "  Username: xavilopez581661@agentforce.com"
echo "  Instance URL: https://login.salesforce.com"
echo "  (No changes needed)"
echo ""

# Export credentials
echo "========================================================================"
echo "STEP 7: Exporting Credentials"
echo "========================================================================"
echo ""

mkdir -p credentials

echo "Exporting DEV credentials..."
sf org display --target-org persistent-dev --json > credentials/dev-credentials.json

echo "Exporting QA credentials..."
sf org display --target-org persistent-qa --json > credentials/qa-credentials.json

echo "Exporting UAT credentials..."
sf org display --target-org persistent-uat --json > credentials/uat-credentials.json

echo "✅ Credentials exported to credentials/ folder"
echo ""

# Summary
echo "========================================================================"
echo "  SETUP COMPLETE - SUMMARY"
echo "========================================================================"
echo ""
echo "✅ Environments Created Successfully:"
echo ""
echo "┌─────────┬────────────────────┬───────────────────────────────────┐"
echo "│ ENV     │ ALIAS              │ USERNAME                          │"
echo "├─────────┼────────────────────┼───────────────────────────────────┤"
printf "│ DEV     │ persistent-dev     │ %-33s │\n" "$DEV_USERNAME"
printf "│ QA      │ persistent-qa      │ %-33s │\n" "$QA_USERNAME"
printf "│ UAT     │ persistent-uat     │ %-33s │\n" "$UAT_USERNAME"
echo "│ PROD    │ (Developer Ed)     │ xavilopez581661@agentforce.com    │"
echo "└─────────┴────────────────────┴───────────────────────────────────┘"
echo ""
echo "Expiration Date: $(date -d '+30 days' '+%Y-%m-%d' 2>/dev/null || date -v+30d '+%Y-%m-%d' 2>/dev/null || echo '2026-02-10')"
echo ""
echo "⚠️  IMPORTANT NEXT STEPS:"
echo ""
echo "1. Store credentials in Azure DevOps Variable Groups"
echo "   Run: ./scripts/export-azure-variables.sh"
echo ""
echo "2. Set calendar reminder for $(date -d '+28 days' '+%Y-%m-%d' 2>/dev/null || date -v+28d '+%Y-%m-%d' 2>/dev/null || echo '2026-02-08')"
echo "   to re-run this script before orgs expire"
echo ""
echo "3. View all orgs:"
echo "   sf org list"
echo ""
echo "4. Open any org:"
echo "   sf org open --target-org persistent-dev"
echo "   sf org open --target-org persistent-qa"
echo "   sf org open --target-org persistent-uat"
echo ""
echo "========================================================================"
echo "  Setup script completed successfully!"
echo "========================================================================"