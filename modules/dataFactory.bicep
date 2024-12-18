// Parameters for Data Factory
param module_customerName string
param module_location string


// Variables for Data Factory
resource module_DataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: module_customerName
  properties: {
    repoConfiguration: {
      type: 'FactoryVSTSConfiguration'
      accountName: 'Customer_Advisory'
      repositoryName: module_customerName
      projectName: 'Customer_Internal'
      collaborationBranch: 'main'
      rootFolder: '/'
    }
    publicNetworkAccess: 'Enabled'
  }
  location: module_location
  identity: {
    type: 'SystemAssigned'
  }
}
