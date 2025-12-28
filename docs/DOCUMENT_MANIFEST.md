# Documentation Manifest

This file lists all documentation in the system, organized by skill level and type.

## Legend
- ✅ Complete and reviewed
- 🚧 In progress
- 📝 Planned (use template to create)

---

## Day 1 Documents

### Concepts
- ✅ `concept-iac-overview.md` - What is Infrastructure as Code?
- 📝 `concept-team-workflow.md` - How Our Team Works with IaC

### How-To Guides
- ✅ `howto-environment-setup.md` - Set Up Your Development Environment
- 📝 `howto-first-git-commit.md` - Making Your First Git Commit
- 📝 `howto-access-azure-portal.md` - Navigating the Azure Portal

### Learning Paths
- 📝 `learning-path-day1.md` - Day 1: Getting Started

---

## Week 1-4 Documents

### Concepts
- 📝 `concept-terraform-workflow.md` - Understanding Terraform Workflow (init, plan, apply)
- 📝 `concept-terraform-state.md` - What is Terraform State?
- 📝 `concept-azure-resource-hierarchy.md` - Understanding Azure Organization
- 📝 `concept-modules.md` - What Are Terraform Modules?

### How-To Guides
- 📝 `howto-terraform-first-deployment.md` - Your First Terraform Deployment
- 📝 `howto-use-approved-modules.md` - Using Team-Approved Modules
- 📝 `howto-deploy-resource-group.md` - Deploy an Azure Resource Group
- 📝 `howto-deploy-storage-account.md` - Deploy an Azure Storage Account
- 📝 `howto-read-terraform-plan.md` - Understanding Terraform Plan Output

---

## Month 1-2 Documents

### Concepts
- 📝 `concept-state-backend.md` - Remote State and Backends
- 📝 `concept-variables-outputs.md` - Terraform Variables and Outputs
- 📝 `concept-terraform-modules-deep.md` - Module Design Patterns

### How-To Guides
- 📝 `howto-configure-backend.md` - Configure Azure Storage Backend
- 📝 `howto-create-module.md` - Create a Reusable Terraform Module
- 📝 `howto-multi-environment.md` - Deploy to Multiple Environments
- 📝 `howto-use-variables.md` - Using Variables in Terraform
- 📝 `howto-virtual-network.md` - Deploy a Virtual Network

---

## Month 3-6 Documents

### Concepts
- 📝 `concept-advanced-state.md` - Advanced State Management
- 📝 `concept-terraform-workspaces.md` - Understanding Workspaces
- 📝 `concept-pipeline-architecture.md` - CI/CD Pipeline Design for IaC

### How-To Guides
- 📝 `howto-advanced-modules.md` - Advanced Module Patterns
- 📝 `howto-create-pipeline.md` - Create Azure DevOps Pipeline for Terraform
- 📝 `howto-module-versioning.md` - Module Versioning and Registry
- 📝 `howto-complex-networking.md` - Complex Network Architectures

---

## Month 6-12 Documents

### Concepts
- 📝 `concept-architecture-decisions.md` - Making Architecture Decisions
- 📝 `concept-terraform-best-practices.md` - Enterprise Terraform Patterns

### How-To Guides
- 📝 `howto-lead-iac-project.md` - Leading an IaC Initiative
- 📝 `howto-mentor-team.md` - Mentoring Team Members on IaC
- 📝 `howto-evaluate-tools.md` - Evaluating New IaC Tools and Practices

---

## Reference Documents

### Standards
- ✅ `reference-naming-conventions.md` - Azure Resource Naming Standards
- 📝 `reference-tagging-standards.md` - Resource Tagging Standards
- 📝 `reference-resource-organization.md` - How to Organize Resources

### Commands & Syntax
- 📝 `reference-terraform-commands.md` - Complete Terraform CLI Reference
- 📝 `reference-azurerm-provider.md` - azurerm Provider Configuration
- 📝 `reference-hcl-syntax.md` - HCL Syntax Quick Reference

### Specifications
- 📝 `reference-module-standards.md` - Team Module Development Standards
- 📝 `reference-security-requirements.md` - Security and Compliance Requirements
- 📝 `reference-approved-modules.md` - Approved Module Catalog

---

## Troubleshooting Guides

### Authentication & Access
- 📝 `troubleshooting-authentication-issues.md` - Authentication and Login Problems
- 📝 `troubleshooting-permissions.md` - Permission and RBAC Issues

### Terraform Operations
- 📝 `troubleshooting-state-lock.md` - State Lock Errors
- 📝 `troubleshooting-state-drift.md` - Configuration Drift and State Issues
- 📝 `troubleshooting-init-errors.md` - Terraform Init Failures
- 📝 `troubleshooting-plan-errors.md` - Plan and Validation Errors
- 📝 `troubleshooting-apply-failures.md` - Apply Failures and Rollback

### Azure-Specific
- 📝 `troubleshooting-azure-resources.md` - Azure Resource Deployment Issues
- 📝 `troubleshooting-networking.md` - Network Configuration Problems
- 📝 `troubleshooting-quota-limits.md` - Quota and Limit Errors

### Pipeline Issues
- 📝 `troubleshooting-pipeline-failures.md` - Azure DevOps Pipeline Problems
- 📝 `troubleshooting-cicd.md` - CI/CD Integration Issues

---

## Learning Paths

- 📝 `learning-path-day1.md` - Day 1: Complete Onboarding
- 📝 `learning-path-week1-4.md` - Weeks 1-4: Terraform Fundamentals
- 📝 `learning-path-month1-2.md` - Months 1-2: Intermediate Practitioner
- 📝 `learning-path-month3-6.md` - Months 3-6: Advanced Operations
- 📝 `learning-path-month6-12.md` - Months 6-12: Team Leadership
- 📝 `learning-path-azure-specialist.md` - Specialization: Azure Networking
- 📝 `learning-path-module-developer.md` - Specialization: Module Development

---

## Statistics

- **Total Planned**: 50+ documents
- **Completed**: 5 documents (demonstration samples)
- **By Type**:
  - Concepts: 12
  - How-To: 23
  - Reference: 9
  - Troubleshooting: 9
  - Learning Paths: 7

---

## Contributing

To create a new document:

1. Choose appropriate template from `/templates`
2. Place in correct directory based on skill level
3. Follow naming convention: `[type]-[descriptive-name].md`
4. Complete all metadata fields
5. Add to this manifest
6. Submit for review

See [Documentation System Guide](../DOCUMENTATION_SYSTEM_GUIDE.md) for detailed instructions.

---

**Note**: This manifest represents the complete documentation vision. The system includes 5 fully-developed sample documents demonstrating all document types and the complete structure. Additional documents can be created using the templates as the team grows and needs evolve.
