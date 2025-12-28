# GEMINI.md

This file provides guidance to Gemini when working with code in this repository.

## Project Overview

This project is an **IaC Documentation Modernization & AI Search POC**. It's a comprehensive solution for managing Infrastructure as Code (IaC) team documentation, featuring AI-powered natural language search capabilities. The project is built on a three-layer architecture:

1.  **Documentation Layer**: Markdown documents with rich metadata, organized into a progressive learning framework (from Day 1 to 12 months). It uses five document types: Concept, How-To, Reference, Troubleshooting, and Learning Paths. A central glossary is maintained in `config/glossary.yaml`.
2.  **Automation Layer**: PowerShell scripts for deploying, validating, and testing the system.
3.  **Infrastructure Layer**: Azure resources managed by Terraform, including Azure AI Search, Azure OpenAI, Azure Storage, and an Azure Function App.

The primary goal is to create a self-service documentation system that reduces onboarding time and makes it easy to find information through natural language queries.

## Building and Running

This project is deployed to Azure using a combination of PowerShell scripts and Terraform.

### Prerequisites

*   PowerShell 7.4+
*   Terraform 1.5+
*   Azure CLI 2.50+
*   An Azure subscription with appropriate permissions

### Quick Start (Recommended)

The easiest way to get started is to use the fully automated `Quick-Start.ps1` script. This script checks for prerequisites, authenticates to Azure, and deploys the entire infrastructure.

```powershell
pwsh ./Quick-Start.ps1
```

### Manual Deployment

For more control over the deployment process, you can use the following steps:

1.  **Authenticate to Azure**:
    ```bash
    az login
    az account set --subscription "Your-Subscription-Name"
    ```

2.  **Deploy the Infrastructure**:
    This script will deploy the Azure resources using Terraform. You can specify the SKU for the search service.
    ```powershell
    # Deploy with the free tier (for testing)
    pwsh ./scripts/deployment/Deploy-IaCDocsPOC.ps1

    # Deploy with the basic tier
    pwsh ./scripts/deployment/Deploy-IaCDocsPOC.ps1 -SearchSku basic
    ```

3.  **Destroy the Infrastructure**:
    To avoid ongoing costs, you can destroy all the deployed resources with a single command.
    ```powershell
    pwsh ./scripts/deployment/Destroy-IaCDocsPOC.ps1
    ```

### Testing and Validation

*   **Document Quality Validation**:
    This script checks the documentation for completeness of metadata, readability, and other quality metrics.
    ```powershell
    # Validate a single document
    pwsh ./scripts/validation/Test-DocumentQuality.ps1 -Path "./docs/day1/concept-iac-overview.md"

    # Validate all documents
    pwsh ./scripts/validation/Test-DocumentQuality.ps1 -Path "./docs"
    ```

*   **Search Quality Testing**:
    After deploying the infrastructure, you can test the search relevance with this script.
    ```powershell
    # Test search relevance
    pwsh ./scripts/testing/Test-SearchQuality.ps1 -TestQueries @("how to deploy terraform", "what is infrastructure as code")
    ```

## Development Conventions

### Documentation

*   **Always use templates**: New documents should be created from the templates in the `templates/` directory.
*   **Metadata is mandatory**: All documents must have complete YAML frontmatter, as defined in the templates and `CLAUDE.md`.
*   **Progressive structure**: Documents are organized by skill level in the `docs/` directory (e.g., `day1`, `week1-4`, etc.).
*   **Glossary**: All technical terms should be defined in `config/glossary.yaml` and referenced in the document's `glossary_terms` metadata.

### Infrastructure (Terraform)

*   **Modular Architecture**: The Terraform code is organized into modules located in `terraform/modules/`.
*   **Environments**: The main deployment configuration is in `terraform/environments/poc/`.
*   **Naming Conventions**: Resources are named using a consistent convention defined in `terraform/environments/poc/main.tf` (e.g., `{resource-type}-{workload}-{environment}-{region-code}`).

### Automation (PowerShell)

*   Scripts are located in the `scripts/` directory, organized by purpose (e.g., `deployment`, `validation`).
*   Scripts should follow PowerShell best practices and include comment-based help.
