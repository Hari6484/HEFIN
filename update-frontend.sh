#!/bin/bash

# Deploy Frontend Only Script for HEFIN Decentralized Platform
set -e

echo "🚀 Updating HEFIN UI Canister on IC Mainnet"
echo "=========================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check current identity
CURRENT_IDENTITY=$(dfx identity whoami)
echo -e "${BLUE}Current identity: ${CURRENT_IDENTITY}${NC}"

# Handle identity setup for mainnet
if [ "$CURRENT_IDENTITY" = "default" ]; then
    echo -e "${YELLOW}⚠️ Using default identity. Suppressing mainnet warning...${NC}"
    export DFX_WARNING=-mainnet_plaintext_identity
fi

# MODIFIED: Get existing HEFIN canister IDs (These IDs are placeholders and should be real mainnet IDs)
echo -e "${BLUE}📋 Reading existing HEFIN backend canister IDs...${NC}"
HEFIN_USER_DATA_ID="7k5cu-siaaa-aaaao-a4paa-cai"        # Replaces dao_backend
HEFIN_CLAIMS_LOGIC_ID="7d6ji-eaaaa-aaaao-a4pbq-cai"      # Replaces governance
HEFIN_AI_FRAUD_ID="6suxx-4iaaa-aaaao-a4pea-cai"          # Replaces staking
HEFIN_FINANCIAL_LEDGER_ID="6vvrd-rqaaa-aaaao-a4peq-cai"  # Replaces treasury
HEFIN_INTEGRATION_API_ID="772tz-taaaa-aaaao-a4pdq-cai"   # Replaces proposals

echo "Using existing HEFIN canister IDs:"
echo "User Data:       ${HEFIN_USER_DATA_ID}"
echo "Claims Logic:    ${HEFIN_CLAIMS_LOGIC_ID}"
echo "AI Fraud:        ${HEFIN_AI_FRAUD_ID}"
echo "Financial Ledger: ${HEFIN_FINANCIAL_LEDGER_ID}"
echo "Integration API:  ${HEFIN_INTEGRATION_API_ID}"

# Update environment variables with actual canister IDs
echo -e "${BLUE}🔧 Updating environment variables for frontend build...${NC}"

# MODIFIED: Update the frontend .env.production file path and variables
cat > src/hefin_ui_canister/.env.production << EOF
# Production environment variables for HEFIN mainnet deployment
VITE_CANISTER_ID_USER_DATA=$HEFIN_USER_DATA_ID
VITE_CANISTER_ID_CLAIMS_LOGIC=$HEFIN_CLAIMS_LOGIC_ID
VITE_CANISTER_ID_AI_FRAUD=$HEFIN_AI_FRAUD_ID
VITE_CANISTER_ID_FINANCIAL_LEDGER=$HEFIN_FINANCIAL_LEDGER_ID
VITE_CANISTER_ID_INTEGRATION_API=$HEFIN_INTEGRATION_API_ID
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
# MODIFIED: Change directory to the HEFIN frontend path
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

# Verify environment variables in build (Checking one of the new HEFIN IDs)
echo "Verifying environment variables in build..."
if grep -q "VITE_CANISTER_ID_AI_FRAUD:\"\"" dist/assets/*.js; then
    echo -e "${RED}❌ Build failed - AI FRAUD canister ID is empty!${NC}"
    exit 1
fi

# Show what environment variables were included
echo "Environment variables in build:"
grep -o "VITE_CANISTER_ID_[^:]*:[^,}]*" dist/assets/*.js | head -10

echo -e "${GREEN}✅ Frontend build completed successfully${NC}"
cd ../..

# Deploy frontend canister
echo -e "${BLUE}🚀 Deploying HEFIN UI Canister...${NC}"
# MODIFIED: Deploy the HEFIN frontend canister
dfx deploy hefin_ui_canister --network ic

echo -e "${GREEN}✅ Frontend deployment completed successfully!${NC}"

# Get frontend canister ID
HEFIN_FRONTEND_ID=$(dfx canister id hefin_ui_canister --network ic)

echo ""
echo -e "${BLUE}🌐 Your HEFIN UI has been updated!${NC}"
echo ""
echo "🎯 Frontend URL: https://${HEFIN_FRONTEND_ID}.icp0.io/"
echo ""
echo -e "${GREEN}🎉 Frontend update completed successfully!${NC}"