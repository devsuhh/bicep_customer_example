//SQL Parameters
param module_sqlserverName string
param module_location string
@secure()
param module_sqlAdminPassword string



//SQL Server Resource
resource module_customerSqlServer 'Microsoft.Sql/servers@2022-08-01-preview' =  {
  name: module_sqlserverName
  location: module_location
  properties: {
    administratorLogin: 'customer_adminuser'
    administratorLoginPassword: module_customer_AdminPassword 
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
    
    }
}

//SQL Server Customer Database
resource Customer_Database 'Microsoft.Sql/servers/databases@2022-08-01-preview' =  {
  parent: module_customerSqlServer
  name: 'Customer'
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 10
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 268435456000
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Geo'
    isLedgerOn: false
    availabilityZone: 'NoPreference'
  }
  location: module_location
  tags: {}
}

// Output of customer SQL server ID
output output_sql_id string = module_customerSqlServer.id
