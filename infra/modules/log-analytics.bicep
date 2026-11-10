@description('Resource name prefix')
param resourcePrefix string

@description('Azure region')
param location string = resourceGroup().location

@description('Log retention in days (minimum 30 for PerGB2018 SKU)')
param retentionInDays int = 30

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${resourcePrefix}-logs'
  location: location
  properties: {
    retentionInDays: retentionInDays
    sku: {
      name: 'PerGB2018'
    }
  }
}

output workspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name
output customerId string = logAnalyticsWorkspace.properties.customerId
output primarySharedKey string = logAnalyticsWorkspace.listKeys().primarySharedKey