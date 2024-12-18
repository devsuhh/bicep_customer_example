**Azure Resource Deployment Using PowerShell and Bicep**

This repository demonstrates an implementation for deploying Azure resources using PowerShell scripts and Bicep templates. 
- This project was designed for a customer who preferred managing Azure resource deployments via PowerShell, ensuring compatibility across multiple environments.
- The customer wanted resources create for each of their own customers.
- The project was compelted in two months from initial design request with meetings stetup for feedback and improvement until the customer was satisfied.
- No prior knowledge of Azure Bicep was known until this project requiring me to use my expertise from previous technology domains.

**Project Overview**

The solution involves a PowerShell script to facilitate deployment by:

- Allowing the user to select parameter and Bicep files dynamically.
- Validating the availability of resource names and configurations in Azure before deployment.
- Deploying resources to Azure using az deployment sub create.
- A Bicep file that defines the Azure resources at the subscription level, leveraging modular design principles for reusable components.

**Features**
- Compatibility: Works with both PowerShell 5 and 7.
- Interactive Resource Checks: The script validates existing resources and ensures no naming conflicts before deployment.
- Dynamic Parameters: Users can select their desired parameter and Bicep files interactively.
- Secure Input: Sensitive values, such as SQL passwords, are handled securely.
- Azure Native Deployment: Bicep templates follow Azure best practices, utilizing modules for modular and scalable resource management.

**How It Works**

PowerShell Script
- File Selection: Users select JSON parameter and Bicep files from the current directory for deployment.
- Resource Validation: The script checks for the existence of required resources (e.g., resource groups, subnets, SQL servers) in Azure.
- Conditional Execution: Stops execution if naming conflicts or other issues are detected.
- Deployment Execution: Deploys the selected Bicep file with the provided parameters to the specified Azure subscription.

**Bicep File**

- Subscription-Level Deployment: Targets the subscription scope, creating and managing Azure resources such as resource groups, subnets, SQL servers, data factories, and private endpoints.
- Hardcoded parameters for shared resources.
- Dynamic parameters for customer-specific configurations.
- Modules: Encapsulated logic for subnets, data factories, private endpoints, and SQL servers for easier maintainability.

**Bicep Template Structure**

The Bicep file creates resources dynamically based on customer-specific parameters:
- Customer Resource Group: Each customer has a dedicated resource group.
- Subnet: Associated with a shared VNET and NSG.
- Azure Data Factory: Provisioned for customer data workflows.
- Private Endpoint: Secures access to SQL and other resources.
- SQL Server: Configured with secure admin credentials.


**Key Considerations**

- Resource Availability: The script halts if any resource conflicts are detected, ensuring smooth deployments.
- Customizable Modules: The Bicep template is modular, allowing adjustments to resource definitions without affecting the core logic.
- Cross-Environment Compatibility: Designed to work across PowerShell 5 and 7.
