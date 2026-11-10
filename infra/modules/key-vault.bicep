@description('Resource name prefix')
param resourcePrefix string

@description('Azure region')
param location string = resourceGroup().location

@description('Key Vault SKU')
@allowed(['standard', 'premium'])
param sku string = 'standard'

@description('Object ID of the Container App managed identity (for access policy)')
param containerAppIdentityObjectId string = ''

var kvName = take(replace(toLower('stkv${uniqueString(resourceGroup().id, deployment().name)}'), '-', ''), 24)

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: sku
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Add access policy for Container App managed identity (if provided)
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = if (!empty(containerAppIdentityObjectId)) {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        objectId: containerAppIdentityObjectId
        tenantId: subscription().tenantId
        permissions: {
          secrets: ['get', 'list']
        }
      }
    ]
  }
}

output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultId string = keyVault.id