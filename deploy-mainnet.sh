#!/bin/bash

# Deploy to IC Mainnet Script for HEFIN Decentralized Platform
set -e

echo "🚀 Deploying HEFIN Decentralized Platform to IC Mainnet"
echo "======================================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check current identity and cycles... (Identity and Cycles Check remain standard DFX practice)

# Check current identity
CURRENT_IDENTITY=$(dfx identity whoami)
echo -e "${BLUE}Current identity: ${CURRENT_IDENTITY}${NC}"

# Handle identity setup for mainnet
if [ "$CURRENT_IDENTITY" = "default" ]; then
    echo -e "${YELLOW}⚠️ Using default identity. Suppressing mainnet warning...${NC}"
    export DFX_WARNING=-mainnet_plaintext_identity
elif [ "$CURRENT_IDENTITY" = "mainnet_deploy" ] || [ "$CURRENT_IDENTITY" = "mainnet_backup" ]; then
    echo -e "${GREEN}✅ Using secure mainnet identity: ${CURRENT_IDENTITY}${NC}"
else
    echo -e "${YELLOW}⚠️ Using identity: ${CURRENT_IDENTITY}${NC}"
    echo -e "${YELLOW}Make sure this identity has sufficient cycles for deployment${NC}"
fi

# Check cycles balance (using a higher conceptual requirement due to AI model size)
echo -e "${BLUE}💰 Checking cycles balance...${NC}"
REQUIRED_CYCLES="5.0" # Increased requirement for AI models and data storage
if dfx cycles balance --network ic > /dev/null 2>&1; then
    CYCLES_BALANCE=$(dfx cycles balance --network ic)
    echo "Cycles balance: $CYCLES_BALANCE"
    
    # Extract numeric value for comparison
    CYCLES_NUM=$(echo "$CYCLES_BALANCE" | grep -o '[0-9.]*' | head -1)
    
    if (( $(echo "$CYCLES_NUM < $REQUIRED_CYCLES" | bc -l) )); then
        echo -e "${RED}❌ Insufficient cycles for deployment!${NC}"
        echo -e "${YELLOW}You need at least ${REQUIRED_CYCLES}T cycles for HEFIN deployment.${NC}"
        echo -e "${YELLOW}Current balance: $CYCLES_BALANCE${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Sufficient cycles available: $CYCLES_BALANCE${NC}"
else
    echo -e "${YELLOW}⚠️ Could not check cycles balance, proceeding with deployment...${NC}"
fi

# First deploy core data and AI canisters to get their IDs
echo -e "${BLUE}🚀 Deploying HEFIN core backend canisters...${NC}"

# Deploy core canisters in dependency order: Data -> Ledger -> AI/Integration
dfx deploy hefin_user_data --network ic          # 1. Stores encrypted user health/financial data
dfx deploy hefin_financial_ledger --network ic   # 2. Manages transaction records
dfx deploy hefin_ai_fraud --network ic           # 3. Decentralized AI model for fraud/risk
dfx deploy hefin_integration_api --network ic    # 4. Bridge to external partner APIs

# The Claims Logic canister needs the Data, Ledger, and AI IDs for initialization.
echo -e "${BLUE}📦 Deploying Claims Logic with Canister References...${NC}"

# Get the IDs needed for initialization
USER_DATA_ID=$(dfx canister id hefin_user_data --network ic)
AI_FRAUD_ID=$(dfx canister id hefin_ai_fraud --network ic)
LEDGER_ID=$(dfx canister id hefin_financial_ledger --network ic)

# Deploy Claims Logic with proper arguments to set references (Conceptual Initialization)
dfx deploy hefin_claims_logic --network ic \
    --argument "(principal \"$USER_DATA_ID\", principal \"$AI_FRAUD_ID\", principal \"$LEDGER_ID\")"

echo -e "${GREEN}✅ Backend canisters deployed${NC}"

# Update environment variables with actual canister IDs
echo -e "${BLUE}🔧 Updating environment variables with deployed canister IDs...${NC}"

# Get all HEFIN canister IDs
CLAIMS_LOGIC_ID=$(dfx canister id hefin_claims_logic --network ic)
LEDGER_ID=$(dfx canister id hefin_financial_ledger --network ic)
AI_FRAUD_ID=$(dfx canister id hefin_ai_fraud --network ic)
INTEGRATION_API_ID=$(dfx canister id hefin_integration_api --network ic)

# Update the root .env.production file
cat > .env.production << EOF
# Production Environment Variables for HEFIN
VITE_CANISTER_ID_USER_DATA=$USER_DATA_ID
VITE_CANISTER_ID_CLAIMS_LOGIC=$CLAIMS_LOGIC_ID
VITE_CANISTER_ID_AI_FRAUD=$AI_FRAUD_ID
VITE_CANISTER_ID_FINANCIAL_LEDGER=$LEDGER_ID
VITE_CANISTER_ID_INTEGRATION_API=$INTEGRATION_API_ID
VITE_CANISTER_ID_INTERNET_IDENTITY=rdmx6-jaaaa-aaaah-qdrqq-cai

VITE_DFX_NETWORK=ic
VITE_HOST=https://icp0.io
EOF

# Update the frontend .env.production file (assuming frontend is in src/hefin_ui_canister)
cat > src/hefin_ui_canister/.env.production << EOF
# Production environment variables for mainnet deployment
VITE_CANISTER_ID_USER_DATA=$USER_DATA_ID
VITE_CANISTER_ID_CLAIMS_LOGIC=$CLAIMS_LOGIC_ID
VITE_CANISTER_ID_AI_FRAUD=$AI_FRAUD_ID
VITE_CANISTER_ID_FINANCIAL_LEDGER=$LEDGER_ID
VITE_CANISTER_ID_INTEGRATION_API=$INTEGRATION_API_ID
VITE_CANISTER_ID_INTERNET_IDENTITY=rdmx6-jaaaa-aaaah-qdrqq-cai

# Mainnet configuration
VITE_HOST=https://icp0.io
VITE_DFX_NETWORK=ic
VITE_IC_HOST=https://icp0.io
VITE_NODE_ENV=production

# Production build optimizations
VITE_BUILD_MODE=production
VITE_ENABLE_ANALYTICS=true
VITE_ENABLE_ERROR_REPORTING=true
EOF

echo -e "${GREEN}✅ Environment variables updated${NC}"

# Build frontend for production
echo -e "${BLUE}🏗️ Building HEFIN UI Canister for production...${NC}"
cd src/hefin_ui_canister

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing frontend dependencies..."
    npm install
fi

# Clean previous build
rm -rf dist

# Build for production with explicit mode
echo "Building with production configuration..."
NODE_ENV=production npm run build -- --mode production

# Verify build output
if [ ! -d "dist" ]; then
    echo -e "${RED}❌ Frontend build failed - dist directory not found!${NC}"
    exit 1
fi

# Verify environment variables in build (Check one critical ID)
echo "Verifying environment variables in build..."
if grep -q "VITE_CANISTER_ID_AI_FRAUD:\"\"" dist/assets/*.js; then
    echo -e "${RED}❌ Build failed - AI FRAUD canister ID is empty!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend build completed successfully${NC}"
cd ../..

# Deploy frontend canister (assuming frontend canister name is 'hefin_ui_canister')
echo -e "${BLUE}🚀 Deploying frontend canister (hefin_ui_canister)...${NC}"
dfx deploy hefin_ui_canister --network ic

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"

# Get final deployed canister IDs
echo -e "${BLUE}📋 Getting final deployed canister IDs...${NC}"
FRONTEND_ID=$(dfx canister id hefin_ui_canister --network ic)

echo -e "${GREEN}✅ All canisters deployed successfully!${NC}"
echo ""
echo -e "${BLUE}🌐 Your HEFIN Platform is now live on IC Mainnet!${NC}"
echo ""
echo "🎯 Frontend URL: https://${FRONTEND_ID}.icp0.io/"
echo ""
echo -e "${BLUE}📋 Deployed Canister IDs:${NC}"
echo "User Data (Encrypted Vault): ${USER_DATA_ID}"
echo "Claims Logic (Smart Contract): ${CLAIMS_LOGIC_ID}"
echo "AI Fraud (Decentralized AI): ${AI_FRAUD_ID}"
echo "Financial Ledger: ${LEDGER_ID}"
echo "Integration API (Partners): ${INTEGRATION_API_ID}"
echo "Frontend (UI Canister): ${FRONTEND_ID}"
echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "1. Test the Automated Claims workflow via the frontend URL."
echo "2. Notify institutional partners to configure their endpoints via the Integration API."
echo ""
echo -e "${GREEN}🎉 Happy Decentralizing Health and Finance!${NC}"

# Final cycles check
echo -e "${BLUE}💰 Final cycles check...${NC}"
FINAL_BALANCE=$(dfx cycles balance --network ic 2>/dev/null || echo "Unable to check")
echo "Remaining cycles balance: $FINAL_BALANCE"