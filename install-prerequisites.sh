#!/bin/bash

##############################################################################
# Prerequisites Installation Script for IaC Documentation POC
#
# This script installs:
# - Terraform 1.5+
# - PowerShell 7.4+
# - Verifies Azure CLI (already installed)
#
# Tested on: Ubuntu 22.04, Debian, WSL2
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
# Prerequisite Checks
##############################################################################

check_prerequisites() {
    print_header "Checking System Prerequisites"

    # Check if running on Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "This script is designed for Linux/WSL2"
        print_warning "For macOS, use: brew install terraform powershell"
        print_warning "For Windows, use: choco install terraform powershell-core"
        exit 1
    fi

    # Check for sudo
    if ! command_exists sudo; then
        print_error "sudo is required but not found"
        exit 1
    fi
    print_success "sudo available"

    # Check for wget
    if ! command_exists wget; then
        print_step "Installing wget..."
        sudo apt-get update -qq
        sudo apt-get install -y wget
    fi
    print_success "wget available"

    # Check for gpg
    if ! command_exists gpg; then
        print_step "Installing gnupg..."
        sudo apt-get update -qq
        sudo apt-get install -y gnupg
    fi
    print_success "gpg available"

    # Check Azure CLI
    if command_exists az; then
        AZ_VERSION=$(az version --output json 2>/dev/null | grep -o '"azure-cli": "[^"]*"' | cut -d'"' -f4)
        print_success "Azure CLI $AZ_VERSION already installed"
    else
        print_warning "Azure CLI not found - install from: https://aka.ms/InstallAzureCLI"
    fi

    # Check Git
    if command_exists git; then
        GIT_VERSION=$(git --version | cut -d' ' -f3)
        print_success "Git $GIT_VERSION already installed"
    else
        print_warning "Git not found - will be needed for version control"
    fi
}

##############################################################################
# Install Terraform
##############################################################################

install_terraform() {
    print_header "Installing Terraform"

    if command_exists terraform; then
        CURRENT_VERSION=$(terraform version -json 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4 | sed 's/v//')
        print_warning "Terraform $CURRENT_VERSION is already installed"

        read -p "Do you want to upgrade to the latest version? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_step "Skipping Terraform installation"
            return 0
        fi
    fi

    print_step "Adding HashiCorp repository..."

    # Add HashiCorp GPG key
    wget -O- https://apt.releases.hashicorp.com/gpg 2>/dev/null | \
        sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

    # Add HashiCorp repository
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

    print_step "Updating package list..."
    sudo apt-get update -qq

    print_step "Installing Terraform..."
    sudo apt-get install -y terraform

    # Verify installation
    if command_exists terraform; then
        TF_VERSION=$(terraform version -json 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4 | sed 's/v//')
        print_success "Terraform $TF_VERSION installed successfully"

        # Check version meets requirements
        REQUIRED_VERSION="1.5.0"
        if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$TF_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
            print_success "Version meets requirements (>= $REQUIRED_VERSION)"
        else
            print_error "Installed version $TF_VERSION is below required $REQUIRED_VERSION"
            return 1
        fi
    else
        print_error "Terraform installation failed"
        return 1
    fi
}

##############################################################################
# Install PowerShell
##############################################################################

install_powershell() {
    print_header "Installing PowerShell 7"

    if command_exists pwsh; then
        CURRENT_VERSION=$(pwsh --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
        print_warning "PowerShell $CURRENT_VERSION is already installed"

        read -p "Do you want to upgrade to the latest version? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_step "Skipping PowerShell installation"
            return 0
        fi
    fi

    # Detect Ubuntu version
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        UBUNTU_VERSION=$VERSION_ID
    else
        print_warning "Could not detect Ubuntu version, assuming 22.04"
        UBUNTU_VERSION="22.04"
    fi

    print_step "Downloading Microsoft repository configuration..."

    # Download Microsoft repository GPG keys
    wget -q "https://packages.microsoft.com/config/ubuntu/$UBUNTU_VERSION/packages-microsoft-prod.deb" \
        -O /tmp/packages-microsoft-prod.deb

    print_step "Registering Microsoft repository..."
    sudo dpkg -i /tmp/packages-microsoft-prod.deb
    rm /tmp/packages-microsoft-prod.deb

    print_step "Updating package list..."
    sudo apt-get update -qq

    print_step "Installing PowerShell..."
    sudo apt-get install -y powershell

    # Verify installation
    if command_exists pwsh; then
        PWSH_VERSION=$(pwsh --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
        print_success "PowerShell $PWSH_VERSION installed successfully"

        # Check version meets requirements
        REQUIRED_VERSION="7.4.0"
        if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PWSH_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
            print_success "Version meets requirements (>= $REQUIRED_VERSION)"
        else
            print_warning "Installed version $PWSH_VERSION, recommended: >= $REQUIRED_VERSION"
            print_warning "Should still work, but consider upgrading"
        fi
    else
        print_error "PowerShell installation failed"
        return 1
    fi
}

##############################################################################
# Post-Installation Steps
##############################################################################

verify_installation() {
    print_header "Verifying Installation"

    local all_good=true

    # Check Terraform
    if command_exists terraform; then
        TF_VERSION=$(terraform version -json 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
        print_success "Terraform $TF_VERSION"
    else
        print_error "Terraform not found"
        all_good=false
    fi

    # Check PowerShell
    if command_exists pwsh; then
        PWSH_VERSION=$(pwsh --version)
        print_success "$PWSH_VERSION"
    else
        print_error "PowerShell not found"
        all_good=false
    fi

    # Check Azure CLI
    if command_exists az; then
        AZ_VERSION=$(az version --output json 2>/dev/null | grep -o '"azure-cli": "[^"]*"' | cut -d'"' -f4)
        print_success "Azure CLI $AZ_VERSION"
    else
        print_warning "Azure CLI not found (optional, but recommended)"
    fi

    # Check Git
    if command_exists git; then
        GIT_VERSION=$(git --version)
        print_success "$GIT_VERSION"
    else
        print_warning "Git not found (optional, but recommended)"
    fi

    echo ""
    if [ "$all_good" = true ]; then
        print_success "All required tools are installed!"
        return 0
    else
        print_error "Some tools failed to install"
        return 1
    fi
}

show_next_steps() {
    print_header "Next Steps"

    echo -e "${CYAN}You're almost ready to deploy! Here's what to do next:${NC}\n"

    echo -e "${YELLOW}1. Authenticate to Azure:${NC}"
    echo -e "   ${GREEN}az login${NC}"
    echo ""

    echo -e "${YELLOW}2. Run the prerequisite check:${NC}"
    echo -e "   ${GREEN}pwsh ./scripts/deployment/Test-Prerequisites.ps1${NC}"
    echo ""

    echo -e "${YELLOW}3. Deploy the POC:${NC}"
    echo -e "   ${GREEN}pwsh ./Quick-Start.ps1${NC}"
    echo ""

    echo -e "${YELLOW}OR run everything automatically:${NC}"
    echo -e "   ${GREEN}az login && pwsh ./Quick-Start.ps1${NC}"
    echo ""

    echo -e "${CYAN}Estimated deployment time: 15 minutes${NC}"
    echo -e "${CYAN}Estimated monthly cost: ~\$12 (can destroy anytime)${NC}\n"
}

##############################################################################
# Main Execution
##############################################################################

main() {
    print_header "IaC Documentation POC - Prerequisites Installation"

    echo -e "This script will install:"
    echo -e "  • Terraform (>= 1.5.0)"
    echo -e "  • PowerShell 7 (>= 7.4.0)"
    echo ""
    echo -e "Installation requires sudo privileges."
    echo ""

    read -p "Continue with installation? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi

    # Run installation steps
    check_prerequisites

    if install_terraform && install_powershell; then
        if verify_installation; then
            show_next_steps
            exit 0
        else
            print_error "Installation verification failed"
            exit 1
        fi
    else
        print_error "Installation failed"
        exit 1
    fi
}

# Run main function
main "$@"
