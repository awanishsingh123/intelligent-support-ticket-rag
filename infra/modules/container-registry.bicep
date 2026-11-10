@description('Resource name prefix')
param resourcePrefix string

@description('Azure region')
param location string = resourceGroup().location

@description('ACR SKU (Basic, Standard, Premium)')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Basic'

@description('Enable admin user (not recommended for production)')
param adminUserEnabled bool = false

var acrName = take(replace(toLower('stacr${uniqueString(resourceGroup().id, deployment().name)}'), '-', ''), 50)

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Enabled'
  }
}

output acrName string = containerRegistry.name
output acrLoginServer string = containerRegistry.properties.loginServer
output acrResourceId string = containerRegistry.id