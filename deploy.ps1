<#
.SYNOPSIS
    Deploy Customer Support Ticket System to Azure Container Apps
.DESCRIPTION
    Two-phase deployment:
    Phase 1: Deploy infrastructure with placeholder image
    Phase 2: Build/push real image, configure ACR auth, update Container App
.NOTES
    Requires: Azure CLI, logged in with appropriate subscription
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId = "38d6b49d-6042-4f94-9962-0f299d8935e6",
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup = "rg-support-ticket",
    
    [Parameter(Mandatory=$true)]
    [string]$Location = "eastus",
    
    [string]$ResourcePrefix = "support-ticket",
    
    [string]$EnvironmentName = "prod"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Check-AzCli {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI not found. Install from https://aka.ms/installazurecliwindows"
    }
    Write-Log "Azure CLI found: $(az version --query 'azure-cli' -o tsv)"
}

function Set-Subscription {
    param([string]$SubId)
    Write-Log "Setting subscription to $SubId"
    az account set --subscription $SubId | Out-Null
    $ctx = az account show --query "{name:name, id:id}" -o json | ConvertFrom-Json
    Write-Log "Active subscription: $($ctx.name) ($($ctx.id))"
}

function Create-ResourceGroup {
    param([string]$RgName, [string]$Loc)
    Write-Log "Creating resource group $RgName in $Loc"
    az group create --name $RgName --location $Loc | Out-Null
}

function Deploy-Infrastructure {
    param([string]$RgName, [string]$Prefix, [string]$Env, [string]$Loc)
    Write-Log "Phase 1: Deploying infrastructure (placeholder image)..."
    $deployment = az deployment group create `
        --resource-group $RgName `
        --template-file infra/main.bicep `
        --parameters resourcePrefix=$Prefix environmentName=$Env location=$Loc `
        --query "properties.outputs" -o json
    
    if (-not $deployment) {
        throw "Deployment failed"
    }
    
    $outputs = $deployment | ConvertFrom-Json
    Write-Log "Infrastructure deployed successfully"
    return $outputs
}

function Build-And-Push-Image {
    param([string]$AcrName, [string]$BackendPath)
    Write-Log "Phase 2: Building and pushing image to ACR..."
    az acr build --registry $AcrName --image support-ticket-api:latest $BackendPath
    Write-Log "Image built and pushed successfully"
}

function Configure-AcrAuth {
    param([string]$AppName, [string]$RgName, [string]$AcrServer)
    Write-Log "Configuring ACR authentication with managed identity..."
    az containerapp registry set `
        --name $AppName `
        --resource-group $RgName `
        --server $AcrServer `
        --identity system
    Write-Log "ACR authentication configured"
}

function Update-ContainerAppImage {
    param([string]$AppName, [string]$RgName, [string]$Image)
    Write-Log "Updating Container App with real image..."
    az containerapp update `
        --name $AppName `
        --resource-group $RgName `
        --image $Image
    Write-Log "Container App updated"
}

function Set-KeyVaultSecrets {
    param([string]$KvName, [string]$CohereKey, [string]$GroqKey, [string]$PineconeKey, 
          [string]$PgPassword, [string]$PgHost, [string]$OllamaUrl, [string]$CorsOrigins)
    
    Write-Log "Setting Key Vault secrets..."
    $secrets = @{
        "COHERE-API-KEY" = $CohereKey
        "GROQ-API-KEY" = $GroqKey
        "PINECONE-API-KEY" = $PineconeKey
        "PGPASSWORD" = $PgPassword
        "PGHOST" = $PgHost
        "OLLAMA-BASE-URL" = $OllamaUrl
        "CORS-ORIGINS" = $CorsOrigins
    }
    
    foreach ($secret in $secrets.GetEnumerator()) {
        az keyvault secret set --vault-name $KvName --name $secret.Key --value $secret.Value | Out-Null
        Write-Log "  Set secret: $($secret.Key)"
    }
}

function Grant-KeyVaultAccess {
    param([string]$KvName, [string]$PrincipalId)
    Write-Log "Granting Container App access to Key Vault..."
    az keyvault set-policy --name $KvName --object-id $PrincipalId --secret-permissions get list | Out-Null
    Write-Log "Key Vault access granted"
}

function Restart-ContainerApp {
    param([string]$AppName, [string]$RgName)
    Write-Log "Restarting Container App to pick up new secrets..."
    az containerapp update --name $AppName --resource-group $RgName --set properties.template.revisionSuffix="deploy-$(Get-Date -Format 'yyyyMMddHHmmss')" | Out-Null
    Write-Log "Container App restarted"
}

function Verify-Deployment {
    param([string]$AppUrl)
    Write-Log "Verifying deployment..."
    $healthUrl = "$AppUrl/health"
    $maxRetries = 10
    $retryDelay = 30
    
    for ($i = 1; $i -le $maxRetries; $i++) {
        Write-Log "Health check attempt $i/$maxRetries..."
        try {
            $response = Invoke-WebRequest -Uri $healthUrl -Method Get -TimeoutSec 30 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Log "Health check PASSED!" "SUCCESS"
                $content = $response.Content | ConvertFrom-Json
                Write-Log "Response: $($content | ConvertTo-Json)"
                return $true
            }
        } catch {
            Write-Log "Health check failed: $($_.Exception.Message)" "WARN"
        }
        Start-Sleep -Seconds $retryDelay
    }
    
    throw "Health check failed after $maxRetries attempts"
}

# Main execution
Write-Log "=== Customer Support Ticket System Deployment ==="
Write-Log "Subscription: $SubscriptionId"
Write-Log "Resource Group: $ResourceGroup"
Write-Log "Location: $Location"
Write-Log "Prefix: $ResourcePrefix"
Write-Log "Environment: $EnvironmentName"

Check-AzCli
Set-Subscription $SubscriptionId
Create-ResourceGroup $ResourceGroup $Location

# Phase 1: Deploy infrastructure
$outputs = Deploy-Infrastructure $ResourceGroup $ResourcePrefix $EnvironmentName $Location

$acrName = $outputs.acrName.value
$acrLoginServer = $outputs.acrLoginServer.value
$appName = $outputs.containerAppName.value
$appUrl = $outputs.containerAppUrl.value
$kvName = $outputs.keyVaultName.value
$appPrincipalId = $outputs.systemAssignedMIPrincipalId.value

Write-Log "=== Phase 1 Complete ==="
Write-Log "ACR: $acrName ($acrLoginServer)"
Write-Log "Container App: $appName"
Write-Log "App URL: $appUrl"
Write-Log "Key Vault: $kvName"
Write-Log "App Identity: $appPrincipalId"

# Prompt for secrets
Write-Log ""
Write-Log "=== Enter Required Secrets ==="
$cohereKey = Read-Host "COHERE_API_KEY"
$groqKey = Read-Host "GROQ_API_KEY" -AsSecureString | ConvertFrom-SecureString -AsPlainText
$pineconeKey = Read-Host "PINECONE_API_KEY" -AsSecureString | ConvertFrom-SecureString -AsPlainText
$pgPassword = Read-Host "Supabase PGPASSWORD" -AsSecureString | ConvertFrom-SecureString -AsPlainText
$pgHost = Read-Host "Supabase PGHOST (e.g., db.xxx.supabase.co)"
$corsOrigins = Read-Host "CORS_ORIGINS (e.g., https://your-frontend.vercel.app)"

# Ollama URL (provided by user)
$ollamaUrl = "http://20.219.192.28:11434"

# Phase 2: Build and deploy real image
Build-And-Push-Image $acrName ".\backend"
Configure-AcrAuth $appName $ResourceGroup $acrLoginServer
Update-ContainerAppImage $appName $ResourceGroup "$acrLoginServer/support-ticket-api:latest"

# Configure secrets
Set-KeyVaultSecrets $kvName $cohereKey $groqKey $pineconeKey $pgPassword $pgHost $ollamaUrl $corsOrigins
Grant-KeyVaultAccess $kvName $appPrincipalId
Restart-ContainerApp $appName $ResourceGroup

# Verify
Start-Sleep -Seconds 30
Verify-Deployment $appUrl

Write-Log ""
Write-Log "=== DEPLOYMENT COMPLETE ===" "SUCCESS"
Write-Log "API URL: $appUrl"
Write-Log "Health: $appUrl/health"
Write-Log "Submit Ticket: POST $appUrl/support/submit"
Write-Log ""
Write-Log "Test with:"
Write-Log '  curl -X POST '"$appUrl/support/submit"' -H "Content-Type: application/json" -d '"'"'{"first_name":"Test","last_name":"User","email":"test@example.com","phone":"+1234567890","question":"How do I reset my password?"}'"'"''