@description('Resource name prefix')
param resourcePrefix string

@description('Azure region')
param location string = resourceGroup().location

@description('Log Analytics Workspace Customer ID')
param logAnalyticsCustomerId string

@description('Log Analytics Workspace Primary Shared Key')
param logAnalyticsSharedKey string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: '${resourcePrefix}-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
    // No VNet injection - uses default public environment
  }
}

output environmentId string = containerAppsEnvironment.id
output environmentName string = containerAppsEnvironment.name
output defaultDomain string = containerAppsEnvironment.properties.defaultDomain