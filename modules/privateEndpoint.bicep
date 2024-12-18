//Parameters for the module
param module_subnetId string
param module_location string
param module_customerPrivateEndpointName string
param module_customerPrivateInterfaceName string
param module_privateLinkServiceID string


//Private Endpoint for the customer
resource module_customerPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-09-01' =  {
  name: module_customerPrivateEndpointName
  location: module_location
  properties: {
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: module_customerPrivateInterfaceName
    subnet: {
      id: module_subnetId
    }
    privateLinkServiceConnections: [
      {
        name: module_customerPrivateEndpointName
        properties: {
          groupIds: [
            'sqlServer'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-approved'
            actionsRequired: 'None'
          }
          privateLinkServiceId: module_privateLinkServiceID
          
        }
      }
    ]
  }
}
