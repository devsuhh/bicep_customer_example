// Paramaters for existing VNET and NSG
param module_existingVNETname string
param module_nsg_id string

// Parameters for new subnet
param module_customersubnetName string
param module_subnetAddressPrefix string

// Referencing an existing VNET
resource module_VNET 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: module_existingVNETname
}

// Creating a new subnet
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' = {
  parent: module_VNET
  name: module_customersubnetName
  properties: {
    addressPrefix: module_subnetAddressPrefix 
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    networkSecurityGroup: {
      id: module_nsg_id
    }
  }
}

// Output of subnet resource
output output_subnet_id string = subnet.id
