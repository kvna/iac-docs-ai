#!/bin/bash

##############################################################################
# Automated Prerequisites Installation (Non-Interactive)
#
# This script automatically installs:
# - Terraform 1.5+
# - PowerShell 7.4+
#
# No prompts - runs completely automatically
##############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

##############################################################################
# Helper Functions
##############################################################################

print_header() {
    echo -e "\n${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║ $(printf "%-61s" "$1") ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
}

print_step() {
    echo -e "${YELLOW}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

##############################################################################
# Main Installation
##############################################################################

print_header "Automated Prerequisites Installation"

echo -e "${CYAN}Installing required tools automatically...${NC}\n"

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    print_error "This script is designed for Linux/WSL2"
    exit 1
fi

##############################################################################
# Install System Dependencies
##############################################################################

print_step "Updating package lists..."
sudo apt-get update -qq

print_step "Installing system dependencies..."
sudo apt-get install -y wget gnupg software-properties-common curl lsb-release 2>&1 | grep -v "^Reading" | grep -v "^Building" || true
print_success "System dependencies installed"

##############################################################################
# Install Terraform
##############################################################################

print_header "Installing Terraform"

if command_exists terraform; then
    CURRENT_VERSION=$(terraform version -json 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4 | sed 's/v//')
    print_warning "Terraform $CURRENT_VERSION already installed - upgrading..."
fi

print_step "Adding HashiCorp repository..."
wget -O- https://apt.releases.hashicorp.com/gpg 2>/dev/null | \
    sudo gpg --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

print_step "Installing Terraform..."
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y terraform 2>&1 | grep -v "^Reading" | grep -v "^Building" || true

if command_exists terraform; then
    TF_VERSION=$(terraform version -json 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    print_success "Terraform $TF_VERSION installed"
else
    print_error "Terraform installation failed"
    exit 1
fi

##############################################################################
# Install PowerShell
##############################################################################

print_header "Installing PowerShell 7"

if command_exists pwsh; then
    CURRENT_VERSION=$(pwsh --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    print_warning "PowerShell $CURRENT_VERSION already installed - upgrading..."
fi

# Detect Ubuntu/Debian version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_VERSION=$VERSION_ID
else
    OS_VERSION="22.04"
fi

print_step "Adding Microsoft repository..."
wget -q "https://packages.microsoft.com/config/ubuntu/$OS_VERSION/packages-microsoft-prod.deb" \
    -O /tmp/packages-microsoft-prod.deb 2>/dev/null

sudo dpkg -i /tmp/packages-microsoft-prod.deb 2>&1 | grep -v "^Selecting" || true
rm -f /tmp/packages-microsoft-prod.deb

print_step "Installing PowerShell..."
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y powershell 2>&1 | grep -v "^Reading" | grep -v "^Building" || true

if command_exists pwsh; then
    PWSH_VERSION=$(pwsh --version)
    print_success "$PWSH_VERSION installed"
else
    print_error "PowerShell installation failed"
    exit 1
fi

##############################################################################
# Verification
##############################################################################

print_header "Installation Complete - Verification"

echo ""
terraform version | head -1
pwsh --version
az version --output json 2>/dev/null | grep -o '"azure-cli": "[^"]*"' || echo "Azure CLI: Not installed (optional)"
git --version || echo "Git: Not installed (optional)"

print_success "All required tools installed successfully!"

##############################################################################
# Next Steps
##############################################################################

print_header "Next Steps"

echo -e "${CYAN}Installation complete! Here's what to do next:${NC}\n"

echo -e "${YELLOW}1. Authenticate to Azure:${NC}"
echo -e "   ${GREEN}az login${NC}\n"

echo -e "${YELLOW}2. Run prerequisite check:${NC}"
echo -e "   ${GREEN}pwsh ./scripts/deployment/Test-Prerequisites.ps1${NC}\n"

echo -e "${YELLOW}3. Deploy the POC:${NC}"
echo -e "   ${GREEN}pwsh ./Quick-Start.ps1${NC}\n"

echo -e "${CYAN}Or run everything in one command:${NC}"
echo -e "   ${GREEN}az login && pwsh ./Quick-Start.ps1${NC}\n"

echo -e "${YELLOW}Estimated time: 15 minutes${NC}"
echo -e "${YELLOW}Estimated cost: ~\$12/month (destroy anytime)${NC}\n"

print_success "Ready to deploy! 🚀"
