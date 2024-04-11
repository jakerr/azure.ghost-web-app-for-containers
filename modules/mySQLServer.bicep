targetScope = 'resourceGroup'

@minLength(3)
@maxLength(63)
param mySQLServerName string

@allowed([
  'B_Gen5_1'
  'B_Gen5_2'
])
param mySQLServerSku string

@description('Database administrator login name')
@minLength(1)
param administratorLogin string

@description('Database administrator password')
@minLength(8)
@maxLength(128)
@secure()
param administratorPassword string

@description('Location to deploy the resources')
param location string = resourceGroup().location

@description('Log Analytics workspace id to use for diagnostics settings')
param logAnalyticsWorkspaceId string

@allowed([
  'Disabled'
  'Enabled'
])
@description('Whether or not geo redundant backup is enabled.')
param geoRedundantBackup string


@allowed([
  'Disabled'
  'SameZone'
  'ZoneRedundant'
])
@description('High availability mode for a server.')
param highAvailabilityMode string


resource mySQLServer 'Microsoft.DBforMySQL/flexibleServers@2021-05-01' = {
  name: mySQLServerName
  location: location
  sku: {
    name: mySQLServerSku
    tier: 'Basic'
  }
  properties: {
    createMode: 'Default'
    version: '8.0'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    backup: {
      geoRedundantBackup: geoRedundantBackup
    }
    highAvailability: { mode: highAvailabilityMode }
  }
}

resource firewallRules 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2021-05-01' = {
  parent: mySQLServer
  name: 'AllowAzureIPs'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource mySQLServerDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: mySQLServer
  name: 'MySQLServerDiagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'MySqlSlowLogs'
        enabled: true
      }
      {
        category: 'MySqlAuditLogs'
        enabled: true
      }
    ]
  }
}

output name string = mySQLServer.name
output fullyQualifiedDomainName string = mySQLServer.properties.fullyQualifiedDomainName
