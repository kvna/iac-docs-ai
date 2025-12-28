---
document_id: howto-environment-setup
document_type: howto
skill_level: day1
topics: [setup, installation, configuration, getting-started]
technologies: [terraform_v1.5+, azure_cli_2.50+, powershell_7.4+, git]
prerequisites:
  - "Windows 10/11 or macOS or Linux workstation"
  - "Administrator/sudo access on your workstation"
  - "Azure subscription access (provided by team lead)"
learning_outcomes:
  - Install all required tools for IaC development
  - Configure authentication to Azure
  - Verify your environment is working correctly
  - Clone the team's Terraform repository
estimated_time: 45
last_reviewed: 2025-12-27
review_status: current
search_keywords:
  - "how to setup iac environment"
  - "install terraform"
  - "setup azure cli"
  - "configure development environment"
  - "getting started with terraform"
  - "first day setup"
related_documents:
  - concept-iac-overview
  - howto-terraform-first-deployment
  - troubleshooting-authentication-issues
glossary_terms:
  - terraform
  - azure_cli
  - powershell
  - az_login
  - subscription
difficulty: beginner
---

# How to Set Up Your IaC Development Environment

## Overview

**Goal**: Configure your workstation with all the tools needed to write and deploy infrastructure as code.

**Prerequisites**:
- ✓ Windows 10/11, macOS 10.15+, or Linux workstation
- ✓ Administrator or sudo access to install software
- ✓ Azure subscription access (your team lead will provide this)
- ✓ Access to team's Azure DevOps repository (will be granted during onboarding)

**What You'll Learn**:
- How to install Terraform, Azure CLI, and PowerShell
- How to configure authentication to Azure
- How to verify everything is working
- How to access team repositories

**Estimated Time**: 45 minutes

## Before You Begin

### Required Tools and Access

You will install:
- **Terraform** v1.5+ - Infrastructure as Code tool
- **Azure CLI** v2.50+ - Command-line tool for Azure
- **PowerShell** v7.4+ - Scripting and automation
- **Git** - Version control
- **Visual Studio Code** (recommended) - Code editor

### Setup Checklist

Before proceeding, ensure:
- [ ] You have administrator/sudo access
- [ ] You have stable internet connection
- [ ] You have received Azure subscription details from team lead
- [ ] You have been granted access to Azure DevOps

## Step-by-Step Instructions

### Step 1: Install Terraform

**Purpose**: Terraform is the primary tool we use to define and deploy infrastructure.

**Action**:

#### For Windows:

1. Download Terraform using Chocolatey (recommended):
   ```powershell
   # Run PowerShell as Administrator
   choco install terraform
   ```

   **Alternative** - Manual installation:
   - Download from https://www.terraform.io/downloads
   - Extract ZIP file
   - Add terraform.exe location to your PATH

2. Verify installation:
   ```powershell
   terraform version
   ```

   **Expected output**:
   ```
   Terraform v1.6.5
   on windows_amd64
   ```

#### For macOS:

1. Install using Homebrew:
   ```bash
   brew tap hashicorp/tap
   brew install hashicorp/tap/terraform
   ```

2. Verify installation:
   ```bash
   terraform version
   ```

#### For Linux:

1. Download and install:
   ```bash
   wget https://releases.hashicorp.com/terraform/1.6.5/terraform_1.6.5_linux_amd64.zip
   unzip terraform_1.6.5_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. Verify installation:
   ```bash
   terraform version
   ```

#### Checkpoint ✓

At this point, verify:
- [ ] `terraform version` command works
- [ ] Version is 1.5.0 or higher
- [ ] No error messages appear

---

### Step 2: Install Azure CLI

**Purpose**: Azure CLI allows you to interact with Azure and authenticate Terraform.

**Action**:

#### For Windows:

1. Download and run the MSI installer:
   ```powershell
   # Using Chocolatey (recommended)
   choco install azure-cli
   ```

   **Alternative** - Manual installation:
   - Download from https://aka.ms/installazurecliwindows
   - Run the MSI installer

2. **Close and reopen your terminal** (required for PATH update)

3. Verify installation:
   ```powershell
   az version
   ```

#### For macOS:

1. Install using Homebrew:
   ```bash
   brew update && brew install azure-cli
   ```

2. Verify installation:
   ```bash
   az version
   ```

#### For Linux:

1. Install using package manager:
   ```bash
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

2. Verify installation:
   ```bash
   az version
   ```

**Expected output** (all platforms):
```json
{
  "azure-cli": "2.55.0",
  "azure-cli-core": "2.55.0",
  ...
}
```

#### Checkpoint ✓

Verify:
- [ ] `az version` command works
- [ ] Version is 2.50.0 or higher
- [ ] JSON output displays correctly

---

### Step 3: Install PowerShell 7

**Purpose**: We use PowerShell for controller scripts and automation tasks.

**Note**: Windows has PowerShell 5.1 built-in, but we use PowerShell 7 (cross-platform version).

**Action**:

#### For Windows:

1. Install using Chocolatey:
   ```powershell
   choco install powershell-core
   ```

   **Alternative** - Download installer:
   - Download from https://github.com/PowerShell/PowerShell/releases
   - Run the MSI installer

2. Launch PowerShell 7 (not Windows PowerShell):
   - Look for "PowerShell 7" in Start Menu

3. Verify installation:
   ```powershell
   $PSVersionTable
   ```

#### For macOS:

1. Install using Homebrew:
   ```bash
   brew install --cask powershell
   ```

2. Launch PowerShell:
   ```bash
   pwsh
   ```

3. Verify installation:
   ```powershell
   $PSVersionTable
   ```

#### For Linux:

1. Follow instructions at: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux

2. Launch PowerShell:
   ```bash
   pwsh
   ```

**Expected output**:
```
Name                           Value
----                           -----
PSVersion                      7.4.0
PSEdition                      Core
...
```

#### Checkpoint ✓

Verify:
- [ ] PowerShell 7 launches successfully
- [ ] PSVersion is 7.4.0 or higher
- [ ] PSEdition shows "Core"

---

### Step 4: Install Git

**Purpose**: Version control for infrastructure code and collaboration.

**Action**:

#### For Windows:

1. Install Git:
   ```powershell
   choco install git
   ```

   **Alternative**: Download from https://git-scm.com/downloads

2. Configure Git with your details:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@company.com"
   ```

#### For macOS:

1. Git is usually pre-installed. Verify:
   ```bash
   git --version
   ```

   If not installed:
   ```bash
   brew install git
   ```

2. Configure Git:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@company.com"
   ```

#### For Linux:

1. Install Git:
   ```bash
   sudo apt-get install git  # Ubuntu/Debian
   # or
   sudo yum install git      # RHEL/CentOS
   ```

2. Configure Git:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@company.com"
   ```

**Verification**:
```bash
git --version
# Expected: git version 2.30.0 or higher

git config --list
# Should show your name and email
```

#### Checkpoint ✓

Verify:
- [ ] `git --version` works
- [ ] Your name is configured
- [ ] Your email is configured

---

### Step 5: Install Visual Studio Code (Recommended)

**Purpose**: VS Code is the recommended editor with excellent Terraform support.

**Action**:

1. Download and install VS Code:
   - Windows/macOS/Linux: https://code.visualstudio.com/

2. Install essential extensions:

   Open VS Code and install these extensions (Ctrl+Shift+X or Cmd+Shift+X):

   - **HashiCorp Terraform** (by HashiCorp)
     - Syntax highlighting
     - Auto-completion
     - Linting

   - **Azure Terraform** (by Microsoft)
     - Azure-specific Terraform support

   - **PowerShell** (by Microsoft)
     - PowerShell editing support

   - **GitLens** (by GitKraken)
     - Enhanced Git capabilities

3. Configure VS Code for Terraform:

   Create or edit `.vscode/settings.json` in your home directory:
   ```json
   {
     "terraform.languageServer.enable": true,
     "editor.formatOnSave": true,
     "[terraform]": {
       "editor.defaultFormatter": "hashicorp.terraform"
     }
   }
   ```

**Alternative Editors**: You can use any text editor, but VS Code provides the best experience.

---

### Step 6: Configure Azure Authentication

**Purpose**: Allow Terraform and Azure CLI to access your Azure subscription.

**Action**:

1. **Log in to Azure**:
   ```bash
   az login
   ```

   This will:
   - Open your web browser
   - Prompt you to log in with your company credentials
   - Authenticate your CLI session

   **Expected result**: Browser shows "You have signed in to the Microsoft Azure Cross-platform Command Line Interface"

2. **Verify your subscription**:
   ```bash
   az account show
   ```

   **Expected output**:
   ```json
   {
     "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
     "name": "Your-Subscription-Name",
     "state": "Enabled",
     "tenantId": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",
     ...
   }
   ```

3. **Set default subscription** (if you have multiple):
   ```bash
   # List all subscriptions
   az account list --output table

   # Set default subscription
   az account set --subscription "Your-Subscription-Name"
   ```

4. **Verify Terraform can authenticate**:

   Create a test directory:
   ```bash
   mkdir ~/terraform-test
   cd ~/terraform-test
   ```

   Create a file named `test.tf`:
   ```hcl
   terraform {
     required_providers {
       azurerm = {
         source  = "hashicorp/azurerm"
         version = "~> 3.85"
       }
     }
   }

   provider "azurerm" {
     features {}
   }

   data "azurerm_subscription" "current" {}

   output "subscription_name" {
     value = data.azurerm_subscription.current.display_name
   }
   ```

   Run:
   ```bash
   terraform init
   terraform apply
   ```

   **Expected result**:
   ```
   Changes to Outputs:
     + subscription_name = "Your-Subscription-Name"

   You can apply this plan to save these new output values to the Terraform
   state, without changing any real infrastructure.

   Do you want to perform these actions?
   Terraform will perform the actions described above.
   Only 'yes' will be accepted to approve.

   Enter a value: yes

   Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

   Outputs:
   subscription_name = "Your-Subscription-Name"
   ```

5. **Clean up test**:
   ```bash
   cd ~
   rm -rf ~/terraform-test
   ```

#### Checkpoint ✓

Verify:
- [ ] `az login` succeeded
- [ ] `az account show` displays your subscription
- [ ] Terraform successfully authenticated to Azure
- [ ] Subscription name displayed correctly

**Common Issues**: If authentication fails, see [Troubleshooting Authentication Issues](../troubleshooting/troubleshooting-authentication-issues.md)

---

### Step 7: Clone Team Repository

**Purpose**: Get access to team's Terraform code and standards.

**Action**:

1. **Authenticate to Azure DevOps**:
   ```bash
   # This configures Git to use Azure DevOps
   git config --global credential.helper manager
   ```

2. **Create workspace directory**:
   ```bash
   # Choose a location for your IaC projects
   mkdir ~/iac-projects
   cd ~/iac-projects
   ```

3. **Clone the repository**:

   **Replace `YOUR-ORG` and `YOUR-PROJECT` with actual values** (provided by team lead):

   ```bash
   git clone https://dev.azure.com/YOUR-ORG/YOUR-PROJECT/_git/terraform-infrastructure
   ```

   When prompted:
   - Enter your company email
   - Enter your password or Personal Access Token (PAT)

4. **Verify repository**:
   ```bash
   cd terraform-infrastructure
   ls -la
   ```

   You should see:
   - `README.md`
   - `modules/` directory
   - `environments/` directory
   - `.gitignore`
   - Other team files

#### Checkpoint ✓

Verify:
- [ ] Repository cloned successfully
- [ ] You can see team's files and directories
- [ ] No error messages

---

## Complete Verification

Let's verify everything is working together:

### Comprehensive Check Script

Run this PowerShell script to verify all tools:

```powershell
# Save this as check-environment.ps1
Write-Host "=== IaC Environment Check ===" -ForegroundColor Cyan

# Check Terraform
Write-Host "`nChecking Terraform..." -ForegroundColor Yellow
try {
    $tfVersion = terraform version
    Write-Host "✓ Terraform installed: $($tfVersion[0])" -ForegroundColor Green
} catch {
    Write-Host "✗ Terraform not found or not in PATH" -ForegroundColor Red
}

# Check Azure CLI
Write-Host "`nChecking Azure CLI..." -ForegroundColor Yellow
try {
    $azVersion = (az version --output json | ConvertFrom-Json).'azure-cli'
    Write-Host "✓ Azure CLI installed: $azVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Azure CLI not found or not in PATH" -ForegroundColor Red
}

# Check PowerShell Version
Write-Host "`nChecking PowerShell..." -ForegroundColor Yellow
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 7) {
    Write-Host "✓ PowerShell $psVersion" -ForegroundColor Green
} else {
    Write-Host "✗ PowerShell 7+ required (found $psVersion)" -ForegroundColor Red
}

# Check Git
Write-Host "`nChecking Git..." -ForegroundColor Yellow
try {
    $gitVersion = git --version
    Write-Host "✓ $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Git not found or not in PATH" -ForegroundColor Red
}

# Check Azure Authentication
Write-Host "`nChecking Azure Authentication..." -ForegroundColor Yellow
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "✓ Authenticated to: $($account.name)" -ForegroundColor Green
} catch {
    Write-Host "✗ Not authenticated to Azure (run 'az login')" -ForegroundColor Red
}

Write-Host "`n=== Check Complete ===" -ForegroundColor Cyan
```

Run it:
```powershell
pwsh ./check-environment.ps1
```

**Expected output**: All checks should show green check marks (✓).

## What You've Accomplished

By completing this guide, you have:
- ✓ Installed Terraform for infrastructure as code
- ✓ Installed Azure CLI for Azure management
- ✓ Installed PowerShell 7 for automation
- ✓ Installed Git for version control
- ✓ Configured authentication to Azure
- ✓ Cloned the team repository

You should now be able to:
- Run Terraform commands
- Authenticate to Azure
- Access team's infrastructure code
- Begin learning IaC practices

## Next Steps

Now that your environment is ready, proceed to:

**Immediate next steps**:
- [ ] Read [What is Infrastructure as Code?](concept-iac-overview.md) to understand the concepts
- [ ] Complete [Your First Terraform Deployment](../week1-4/howto-terraform-first-deployment.md)
- [ ] Review [Team Standards and Conventions](../reference/reference-naming-conventions.md)

**Continue your learning path**:
- Follow the [Day 1 Learning Path](../learning-paths/learning-path-day1.md) for structured onboarding

## Troubleshooting

### Issue: Terraform command not found

**Symptoms**:
- Error message: `terraform: command not found` or `'terraform' is not recognized`

**Cause**: Terraform not in system PATH

**Solution**:
1. **Verify installation location**:
   - Windows: Usually `C:\ProgramData\chocolatey\bin\`
   - macOS: Usually `/usr/local/bin/`
   - Linux: Usually `/usr/local/bin/`

2. **Add to PATH**:
   - Windows: Search "Environment Variables" → Edit System PATH → Add Terraform directory
   - macOS/Linux: Add to `~/.bashrc` or `~/.zshrc`:
     ```bash
     export PATH=$PATH:/usr/local/bin
     ```

3. **Restart terminal** and try again

---

### Issue: az login opens browser but fails

**Symptoms**:
- Browser opens but shows error
- Terminal shows "authentication failed"

**Cause**: Network proxy, firewall, or incorrect credentials

**Solution**:
1. Check if you're behind a corporate proxy:
   ```bash
   az login --use-device-code
   ```
   This provides an alternative authentication method

2. Verify you're using the correct company credentials

3. Check with IT if Azure CLI is blocked by firewall

4. See [Troubleshooting Authentication Issues](../troubleshooting/troubleshooting-authentication-issues.md) for detailed help

---

### Issue: Permission denied when cloning repository

**Symptoms**:
- `Permission denied (publickey)` or `fatal: Authentication failed`

**Cause**: Git not authenticated to Azure DevOps

**Solution**:
1. Ensure you have access (check with team lead)
2. Use Personal Access Token (PAT) instead of password:
   - Go to Azure DevOps → User Settings → Personal Access Tokens
   - Create new token with "Code (Read)" permission
   - Use token as password when cloning

3. Configure credential helper:
   ```bash
   git config --global credential.helper manager
   ```

---

## External Resources

- **Terraform Installation**: https://learn.hashicorp.com/tutorials/terraform/install-cli
- **Azure CLI Installation**: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
- **PowerShell 7 Installation**: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell
- **VS Code**: https://code.visualstudio.com/docs

## Glossary Terms Used

Terms defined in the [Glossary](../../config/glossary.yaml):

- **Terraform**: Infrastructure as Code tool used to define and provision cloud infrastructure
- **Azure CLI**: Command-line tool for managing Azure resources and authentication
- **PowerShell**: Cross-platform automation and scripting language
- **az login**: Command to authenticate Azure CLI with your Azure account
- **Subscription**: Azure billing and resource container

---

**Document Metadata**:
- **Last Updated**: 2025-12-27
- **Reviewed By**: DevOps Team Lead
- **Next Review**: 2026-03-27
- **Tested On**: Windows 11, macOS 14, Ubuntu 22.04

---

**Feedback**: Did this guide work for you? Report issues to [team-channel] or update this doc via pull request.
