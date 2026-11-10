@description('Resource name prefix')
param resourcePrefix string

@description('Azure region')
param location string = resourceGroup().location

@description('Container Apps Environment ID')
param environmentId string

@description('Container image name (placeholder for Phase 1)')
param containerImageName string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Key Vault URI for secret references')
param keyVaultUri string

@description('Application Insights Connection String')
param appInsightsConnectionString string

@description('CPU cores (e.g., 0.5, 1, 2)')
param cpu string = '0.5'

@description('Memory in GiB')
param memory string = '1Gi'

@description('Minimum replicas')
param minReplicas int = 1

@description('Maximum replicas')
param maxReplicas int = 3

@description('Target port for ingress')
param targetPort int = 8000

var appName = '${resourcePrefix}-api'

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: appName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    environmentId: environmentId
    configuration: {
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'auto'
        allowInsecure: false
      }
      // Secrets will be added via az containerapp update after Key Vault is populated
    }
    template: {
      containers: [
        {
          name: 'api'
          image: containerImageName
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: [
            { name: 'COHERE_API_KEY', value: 'PLACEHOLDER' }
            { name: 'GROQ_API_KEY', value: 'PLACEHOLDER' }
            { name: 'PINECONE_API_KEY', value: 'PLACEHOLDER' }
            { name: 'PINECONE_INDEX_NAME', value: 'chat-ticket' }
            { name: 'PGPASSWORD', value: 'PLACEHOLDER' }
            { name: 'PGHOST', value: 'PLACEHOLDER' }
            { name: 'PGPORT', value: '5432' }
            { name: 'PGDATABASE', value: 'postgres' }
            { name: 'PGUSER', value: 'postgres' }
            { name: 'OLLAMA_BASE_URL', value: 'http://20.219.192.28:11434' }
            { name: 'CORS_ORIGINS', value: 'https://intelligent-support-ticket-classifi.vercel.app' }
            { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: appInsightsConnectionString }
          ]
          probes: [
            {
              type: 'liveness'
              httpGet: {
                path: '/health'
                port: targetPort
              }
              initialDelaySeconds: 30
              periodSeconds: 30
              failureThreshold: 3
            }
            {
              type: 'readiness'
              httpGet: {
                path: '/health'
                port: targetPort
              }
              initialDelaySeconds: 10
              periodSeconds: 10
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
  }
}

output containerAppName string = containerApp.name
output containerAppId string = containerApp.id
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
output systemAssignedMIPrincipalId string = containerApp.identity.principalId