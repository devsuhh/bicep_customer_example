// This will be deployed at the subscription level
targetScope = 'subscription'

//-------------------------------------PARAMETERS-------------------------------------//

//Parameter-file inputs
param customerName string // Name of the customer
param customerSubnetAddressPrefix string // Address prefix for the customer subnet
param location string  // Location for resources

//Hardcoded parameters
param hardcode_existingVNETname string = 'vnet-shared-prod-eus2' // Address prefix for the customer VNET
param hardcode_existingSharedRG string = 'rg-shared-prod' // Name of the existing resource group for customer networking
param hardcode_existingNSG string = 'nsg-shared-prod' // Name of the existing NSG for the customer subnet

//Interpolated parameters
param interpolated_customerSubnetName string = 'subnet-${customerName}' // Name of the customer subnet
param interpolated_dataFactoryName string = 'adf-${customerName}' // Name of the customer data factory
param interpolated_customerPrivateEndpointName string = 'pe-${customerName}' // Name of the customer private endpoint
param interpolated_customerPrivateEndpointInterfaceName string = 'pi-${customerName}' // Name of the customer private interface
param interpolated_sqlServerName string = 'sql-${customerName}' // Name of the customer SQL Server


//Runtime parameters
@secure()
param sqlServerAdminpassword string // Password for the customer SQL Server admin account


//-------------------------------------RESOURCES-------------------------------------//


// This references an existing resource group for networking
resource existingNetworkingResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: hardcode_existingSharedRG
}

//This references an existing NSG for the customer subnet
resource existingNetworkingNSG 'Microsoft.Network/networkSecurityGroups@2021-02-01' existing = {
  name: hardcode_existingNSG
  scope: existingNetworkingResourceGroup
}

// This creates a resource group for the customer
resource interpolated_customerResourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'rg-${customerName}'
  location: location
}

//-------------------------------------MODULES-------------------------------------//

// Subnet module
// This module creates a subnet for the customer in the specified resource group and virtual network.
module networking './modules/networking.bicep' = {
  name: interpolated_customerSubnetName //Name property is required for modules. However, this is ovewritten by the name parameter below it
  scope: existingNetworkingResourceGroup
  params: {
    module_existingVNETname: hardcode_existingVNETname
    module_subnetAddressPrefix: customerSubnetAddressPrefix
    module_customersubnetName: interpolated_customerSubnetName
    module_nsg_id: existingNetworkingNSG.id
  }
}

// Data Factory module
// This module provisions an Azure Data Factory instance for the customer.
module dataFactory './modules/dataFactory.bicep' = {
  name: interpolated_dataFactoryName
  scope: interpolated_customerResourceGroup
  params: {
    module_customerName: interpolated_dataFactoryName
    module_location: location
  }
}

// Private Endpoint module
// This module provisions an Azure Private Endpoint for the customer.
module privateEndpoint './modules/privateEndpoint.bicep' = {
  name: interpolated_customerPrivateEndpointName
  scope: interpolated_customerResourceGroup
  params: {
    module_subnetId: networking.outputs.output_subnet_id
    module_location: location
    module_customerPrivateEndpointName: interpolated_customerPrivateEndpointName
    module_customerPrivateInterfaceName: interpolated_customerPrivateEndpointInterfaceName
    module_privateLinkServiceID: sql.outputs.output_sql_id
  }
}

// SQL Server module
// This module creates an Azure SQL Server instance for the customer in the specified resource group.
module sql './modules/sql.bicep' = {
  name: interpolated_sqlServerName
  scope: interpolated_customerResourceGroup
  params: {
    module_sqlserverName: interpolated_sqlServerName
    module_location: location
    module_sqlAdminPassword: sqlServerAdminpassword
  }
}











