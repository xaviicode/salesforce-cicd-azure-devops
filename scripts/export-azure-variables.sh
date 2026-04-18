#!/bin/bash

# ============================================================================
# SCRIPT: Export Credentials for Azure DevOps Variable Groups
# Purpose: Extract credentials from Scratch Orgs and format for Azure
# Usage: ./scripts/export-azure-variables.sh
# ============================================================================

echo "========================================================================"
echo "  EXPORT CREDENTIALS FOR AZURE DEVOPS"
echo "========================================================================"
echo ""

# Check if credentials folder exists
if [ ! -d "credentials" ]; then
    echo "❌ ERROR: credentials/ folder not found"
    echo "   Run setup script first: ./scripts/setup-persistent-environments.sh"
    exit 1
fi

# Output file
OUTPUT_FILE="credentials/azure-variables.txt"
> "$OUTPUT_FILE"  # Clear file

echo "Extracting credentials from Scratch Orgs..."
echo ""

# Function to extract and format credentials
extract_credentials() {
    local ENV_NAME=$1
    local CRED_FILE=$2
    local ORG_ALIAS=$3
    
    if [ ! -f "$CRED_FILE" ]; then
        echo "⚠️  $ENV_NAME credentials not found: $CRED_FILE"
        return
    fi
    
    USERNAME=$(jq -r '.result.username' "$CRED_FILE")
    INSTANCE_URL=$(jq -r '.result.instanceUrl' "$CRED_FILE")
    ORG_ID=$(jq -r '.result.id' "$CRED_FILE")
    
    echo "✅ $ENV_NAME credentials extracted"
    
    # Append to output file
    cat >> "$OUTPUT_FILE" << EOF

# ====================================
# $ENV_NAME ENVIRONMENT
# ====================================
${ENV_NAME}_Username=$USERNAME
${ENV_NAME}_Instance_URL=$INSTANCE_URL
${ENV_NAME}_Org_ID=$ORG_ID
${ENV_NAME}_Alias=$ORG_ALIAS

EOF
}

# Extract DEV credentials
extract_credentials "DEV" "credentials/dev-credentials.json" "persistent-dev"

# Extract QA credentials
extract_credentials "QA" "credentials/qa-credentials.json" "persistent-qa"

# Extract UAT credentials
extract_credentials "UAT" "credentials/uat-credentials.json" "persistent-uat"

# Add PROD credentials (manual)
cat >> "$OUTPUT_FILE" << 'EOF'

# ====================================
# PROD ENVIRONMENT
# ====================================
PROD_Username=xavilopez581661@agentforce.com
PROD_Instance_URL=https://login.salesforce.com
PROD_Org_ID=00DpK000000AVVWUAP
PROD_Alias=DevHub

# Note: PROD uses existing Developer Edition
# Client_ID should be the same Connected App for all environments
# OR create separate Connected Apps per environment for better security

EOF

# Add shared variables
cat >> "$OUTPUT_FILE" << 'EOF'

# ====================================
# SHARED VARIABLES
# ====================================
# These should be configured once and reused

Client_ID=<YOUR_CONSUMER_KEY_FROM_CONNECTED_APP>
# This is stored in Azure DevOps Variable Group
# Same for all environments OR separate per environment

DevHub_Username=xavilopez581661@agentforce.com
DevHub_Alias=DevHub

# JWT Key File: server.key
# Stored in: Azure DevOps Secure Files
# Location: /secure-files/server.key

EOF

echo ""
echo "✅ Credentials exported successfully"
echo ""
echo "Output file: $OUTPUT_FILE"
echo ""

# Display the content
cat "$OUTPUT_FILE"

echo ""
echo "========================================================================"
echo "  NEXT STEPS - AZURE DEVOPS CONFIGURATION"
echo "========================================================================"
echo ""
echo "1. Go to Azure DevOps: Pipelines → Library → Variable Groups"
echo ""
echo "2. Edit Variable Group: 'Salesforce_CICD_Variables'"
echo ""
echo "3. Add the following variables (copy from $OUTPUT_FILE):"
echo ""
echo "   DEV Environment:"
echo "     • DEV_Username"
echo "     • DEV_Instance_URL"
echo "     • DEV_Org_ID"
echo ""
echo "   QA Environment:"
echo "     • QA_Username"
echo "     • QA_Instance_URL"
echo "     • QA_Org_ID"
echo ""
echo "   UAT Environment:"
echo "     • UAT_Username"
echo "     • UAT_Instance_URL"
echo "     • UAT_Org_ID"
echo ""
echo "   PROD Environment:"
echo "     • PROD_Username"
echo "     • PROD_Instance_URL"
echo "     • PROD_Org_ID"
echo ""
echo "   Shared:"
echo "     • Client_ID (if not already configured)"
echo "     • DevHub_Username (if not already configured)"
echo ""
echo "4. Verify JWT Key is in Secure Files:"
echo "   Pipelines → Library → Secure Files → server.key"
echo ""
echo "5. Grant pipeline access to Variable Group:"
echo "   Variable Group → Pipeline permissions"
echo "   Add: Salesforce-CD-MultiEnvironment"
echo ""
echo "========================================================================"
echo "  OPTIONAL: Create Separate Connected Apps per Environment"
echo "========================================================================"
echo ""
echo "For enhanced security, you can create separate Connected Apps:"
echo ""
echo "In each Scratch Org (DEV, QA, UAT) and PROD:"
echo "  1. Setup → App Manager → New Connected App"
echo "  2. Name: Salesforce CI/CD - <ENV>"
echo "  3. Enable OAuth Settings"
echo "  4. Enable 'Use digital signatures' → Upload server.key"
echo "  5. Scopes: api, web, refresh_token, offline_access"
echo "  6. Save and copy Consumer Key"
echo ""
echo "Then update variables:"
echo "  DEV_Client_ID=<DEV_CONSUMER_KEY>"
echo "  QA_Client_ID=<QA_CONSUMER_KEY>"
echo "  UAT_Client_ID=<UAT_CONSUMER_KEY>"
echo "  PROD_Client_ID=<PROD_CONSUMER_KEY>"
echo ""
echo "========================================================================"
echo ""
echo "Configuration guide saved to: $OUTPUT_FILE"
echo ""
