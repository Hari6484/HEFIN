#!/bin/bash

# Script to update frontend environment variables with current canister IDs for HEFIN

echo "🔧 Updating HEFIN frontend environment variables..."

# Get current HEFIN canister IDs
HEFIN_USER_DATA_ID=$(dfx canister id hefin_user_data)
HEFIN_FINANCIAL_LEDGER_ID=$(dfx canister id hefin_financial_ledger)
HEFIN_AI_FRAUD_ID=$(dfx canister id hefin_ai_fraud)
HEFIN_CLAIMS_LOGIC_ID=$(dfx canister id hefin_claims_logic)
HEFIN_INTEGRATION_API_ID=$(dfx canister id hefin_integration_api)
HEFIN_UI_CANISTER_ID=$(dfx canister id hefin_ui_canister)
INTERNET_IDENTITY_ID=$(dfx canister id internet_identity)

# Canisters from the original DAO template that have been conceptually replaced:
# DAO_REGISTRY_ID, DAO_ANALYTICS_ID, PROPOSALS_ID, ASSETS_ID are conceptually merged
# or replaced by the HEFIN-specific canisters above. We only list the active HEFIN components.

# Update .env.local file (Assuming frontend is in src/hefin_ui_canister)
cat > src/hefin_ui_canister/.env.local << EOF
# Frontend environment variables for HEFIN local development
VITE_CANISTER_ID_USER_DATA=${HEFIN_USER_DATA_ID}
VITE_CANISTER_ID_FINANCIAL_LEDGER=${HEFIN_FINANCIAL_LEDGER_ID}
VITE_CANISTER_ID_AI_FRAUD=${HEFIN_AI_FRAUD_ID}
VITE_CANISTER_ID_CLAIMS_LOGIC=${HEFIN_CLAIMS_LOGIC_ID}
VITE_CANISTER_ID_INTEGRATION_API=${HEFIN_INTEGRATION_API_ID}
VITE_CANISTER_ID_UI_CANISTER=${HEFIN_UI_CANISTER_ID}
VITE_CANISTER_ID_INTERNET_IDENTITY=${INTERNET_IDENTITY_ID}

# Network configuration
VITE_HOST=http://127.0.0.1:4943
VITE_DFX_NETWORK=local
VITE_IC_HOST=http://127.0.0.1:4943
EOF

echo "✅ HEFIN Environment variables updated:"
echo "User Data (Encrypted Vault): ${HEFIN_USER_DATA_ID}"
echo "Financial Ledger: ${HEFIN_FINANCIAL_LEDGER_ID}"
echo "AI Fraud (Decentralized AI): ${HEFIN_AI_FRAUD_ID}"
echo "Claims Logic (Smart Contract): ${HEFIN_CLAIMS_LOGIC_ID}"
echo "Integration API (Partners): ${HEFIN_INTEGRATION_API_ID}"
echo "UI Canister (Frontend): ${HEFIN_UI_CANISTER_ID}"
echo "Internet Identity: ${INTERNET_IDENTITY_ID}"
echo ""
echo "🔄 Rebuild frontend with: cd src/hefin_ui_canister && npm run build"