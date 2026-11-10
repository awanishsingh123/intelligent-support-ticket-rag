@description('Resource name prefix (used for all resource names)')
param resourcePrefix string = 'support-ticket'

@description('Environment name (e.g., dev, staging, prod)')
param environmentName string = 'prod'

@description('Azure region')
param location string = resourceGroup().location

// Resource name prefix with environment
var namePrefix = '${resourcePrefix}-${environmentName}'

// Phase 1: Deploy Log Analytics Workspace
module logAnalytics './modules/log-analytics.bicep' = {
  name: 'logAnalytics'
  params: {
    resourcePrefix: namePrefix
    location: location
    retentionInDays: 30
  }
}

// Phase 1: Deploy Application Insights
module appInsights './modules/app-insights.bicep' = {
  name: 'appInsights'
  params: {
    resourcePrefix: namePrefix
    location: location
    workspaceId: logAnalytics.outputs.workspaceId
  }
}

// Phase 1: Deploy Container Registry
module containerRegistry './modules/container-registry.bicep' = {
  name: 'containerRegistry'
  params: {
    resourcePrefix: namePrefix
    location: location
    sku: 'Basic'
    adminUserEnabled: false
  }
}

// Phase 1: Deploy Container Apps Environment
module containerAppsEnv './modules/container-apps-env.bicep' = {
  name: 'containerAppsEnv'
  params: {
    resourcePrefix: namePrefix
    location: location
    logAnalyticsCustomerId: logAnalytics.outputs.customerId
    logAnalyticsSharedKey: logAnalytics.outputs.primarySharedKey
  }
}

// Phase 1: Deploy Key Vault (Container App MI not created yet, so no access policy)
module keyVault './modules/key-vault.bicep' = {
  name: 'keyVault'
  params: {
    resourcePrefix: namePrefix
    location: location
    sku: 'standard'
    containerAppIdentityObjectId: ''
  }
}

// Phase 1: Deploy Container App with placeholder image
module containerApp './modules/container-app.bicep' = {
  name: 'containerApp'
  params: {
    resourcePrefix: namePrefix
    location: location
    environmentId: containerAppsEnv.outputs.environmentId
    containerImageName: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
    keyVaultUri: keyVault.outputs.keyVaultUri
    appInsightsConnectionString: appInsights.outputs.connectionString
    cpu: '0.5'
    memory: '1Gi'
    minReplicas: 1
    maxReplicas: 3
    targetPort: 8000
  }
}

// Phase 2: AcrPull role assignment (separate module to avoid circular dependency)
module acrPullRole './modules/acr-pull-role.bicep' = {
  name: 'acrPullRole'
  params: {
    acrName: containerRegistry.outputs.acrName
    principalId: containerApp.outputs.systemAssignedMIPrincipalId
  }
}

output resourcePrefix string = namePrefix
output location string = location
output acrName string = containerRegistry.outputs.acrName
output acrLoginServer string = containerRegistry.outputs.acrLoginServer
output containerAppName string = containerApp.outputs.containerAppName
output containerAppFqdn string = containerApp.outputs.containerAppFqdn
output containerAppUrl string = 'https://${containerApp.outputs.containerAppFqdn}'
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId
output appInsightsConnectionString string = appInsights.outputs.connectionString