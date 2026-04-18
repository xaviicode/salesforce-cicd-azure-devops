#!/bin/bash

# ============================================================================
# SCRIPT: Check Scratch Org Expiration Dates
# Purpose: Verify when persistent Scratch Orgs will expire
# Usage: ./scripts/check-expiration.sh
# Recommendation: Run weekly or set as cron job
# ============================================================================

echo "========================================================================"
echo "  SCRATCH ORG EXPIRATION CHECK"
echo "========================================================================"
echo ""

# Check if Salesforce CLI is installed
if ! command -v sf &> /dev/null; then
    echo "❌ ERROR: Salesforce CLI is not installed"
    exit 1
fi

# Get current date
CURRENT_DATE=$(date +%Y-%m-%d)
CURRENT_TIMESTAMP=$(date +%s)

echo "Current Date: $CURRENT_DATE"
echo ""

# Get Scratch Orgs
SCRATCH_ORGS=$(sf org list --json | jq -r '.result.scratchOrgs[]')

if [ -z "$SCRATCH_ORGS" ]; then
    echo "ℹ️  No Scratch Orgs found"
    echo ""
    echo "Would you like to create persistent environments now?"
    echo "Run: ./scripts/setup-persistent-environments.sh"
    exit 0
fi

echo "Active Scratch Orgs:"
echo ""

# Check each Scratch Org
sf org list --json | jq -r '.result.scratchOrgs[] | 
  select(.alias | contains("persistent")) | 
  {
    alias: .alias,
    username: .username,
    expiration: .expirationDate,
    orgId: .orgId
  }' | jq -r '
  "Alias: \(.alias)",
  "  Username: \(.username)",
  "  Expiration: \(.expiration)",
  "  Org ID: \(.orgId)",
  ""
'

# Calculate days until expiration for persistent orgs
echo "========================================================================"
echo "  EXPIRATION ANALYSIS"
echo "========================================================================"
echo ""

NEEDS_RENEWAL=false

while IFS= read -r line; do
    ALIAS=$(echo "$line" | jq -r '.alias')
    EXPIRATION=$(echo "$line" | jq -r '.expirationDate')
    
    if [ "$ALIAS" != "null" ] && [[ "$ALIAS" == persistent-* ]]; then
        # Calculate days until expiration
        EXPIRATION_TIMESTAMP=$(date -d "$EXPIRATION" +%s 2>/dev/null || echo "0")
        
        if [ "$EXPIRATION_TIMESTAMP" != "0" ]; then
            DAYS_UNTIL_EXPIRATION=$(( ($EXPIRATION_TIMESTAMP - $CURRENT_TIMESTAMP) / 86400 ))
            
            echo "$ALIAS:"
            echo "  Expires: $EXPIRATION"
            
            if [ "$DAYS_UNTIL_EXPIRATION" -le 2 ]; then
                echo "  Status: ⚠️  URGENT - Expires in $DAYS_UNTIL_EXPIRATION days!"
                NEEDS_RENEWAL=true
            elif [ "$DAYS_UNTIL_EXPIRATION" -le 7 ]; then
                echo "  Status: ⚠️  WARNING - Expires in $DAYS_UNTIL_EXPIRATION days"
                NEEDS_RENEWAL=true
            elif [ "$DAYS_UNTIL_EXPIRATION" -le 14 ]; then
                echo "  Status: ℹ️  INFO - Expires in $DAYS_UNTIL_EXPIRATION days"
            else
                echo "  Status: ✅ OK - Expires in $DAYS_UNTIL_EXPIRATION days"
            fi
            echo ""
        fi
    fi
done < <(sf org list --json | jq -c '.result.scratchOrgs[]')

# Recommendations
if [ "$NEEDS_RENEWAL" = true ]; then
    echo "========================================================================"
    echo "  ⚠️  ACTION REQUIRED"
    echo "========================================================================"
    echo ""
    echo "One or more Scratch Orgs are expiring soon!"
    echo ""
    echo "To renew environments, run:"
    echo "  ./scripts/setup-persistent-environments.sh"
    echo ""
    echo "This will:"
    echo "  1. Delete existing Scratch Orgs"
    echo "  2. Create new ones (30 days)"
    echo "  3. Re-export credentials"
    echo ""
    echo "⚠️  WARNING: Any data in Scratch Orgs will be lost"
    echo "   Export important data before renewal"
    echo ""
else
    echo "========================================================================"
    echo "  ✅ ALL ENVIRONMENTS OK"
    echo "========================================================================"
    echo ""
    echo "All persistent Scratch Orgs have sufficient time remaining."
    echo ""
    echo "Next check recommended: $(date -d '+7 days' '+%Y-%m-%d')"
    echo ""
fi

echo "========================================================================"
echo "  USAGE LIMITS"
echo "========================================================================"
echo ""

ACTIVE_COUNT=$(sf org list --json | jq -r '.result.scratchOrgs | length')
echo "Active Scratch Orgs: $ACTIVE_COUNT / 3"

if [ "$ACTIVE_COUNT" -ge 3 ]; then
    echo "Status: ⚠️  At maximum capacity"
elif [ "$ACTIVE_COUNT" -ge 2 ]; then
    echo "Status: ℹ️  High usage"
else
    echo "Status: ✅ Normal usage"
fi

echo ""
echo "Daily limit: 6 Scratch Orgs per day"
echo "Note: Developer Edition limits"
echo ""

echo "========================================================================"
echo "  Check complete"
echo "========================================================================"
