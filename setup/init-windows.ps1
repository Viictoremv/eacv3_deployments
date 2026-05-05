# Requires: az CLI, OpenSSL, base64

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Constants
$ProjectRoot = Get-Location
$VaultName = "kv-aks-eac-eus"
$SecretName = "easv3parent-decryption-key"
$StorageAccount = "saeaceasv3"
$EncContainer = "encrypted-env"
$SqlContainer = "k8sbuildassets"
$TenantId = "ee0f492d-f5b9-4631-af0b-4fa28da42b47"
$SubscriptionId = "207f196d-bd00-4e7e-a3fd-ddcd24135477"

# Paths
$BlobParentEnv = ".env_parent.enc.b64"
$BlobChildEnv = ".env_child.enc.b64"

$TmpParentEnc = "$ProjectRoot\.env_parent.enc"
$TmpChildEnc  = "$ProjectRoot\.env_child.enc"
$TmpParentB64 = "$ProjectRoot\.env_parent.enc.b64"
$TmpChildB64  = "$ProjectRoot\.env_child.enc.b64"

$OutParentEnv = "$ProjectRoot\env\parent\.env.local.override"
$OutChildEnv  = "$ProjectRoot\env\child\.env.local.override"

# SQL dump targets
$SqlChildLocal  = "$ProjectRoot\docker\initdb\child\00-childdbload.sql"
$SqlParentLocal = "$ProjectRoot\docker\initdb\parent\00-parentdbload.sql"

# Check for Azure CLI
if (-not (Get-Command "az" -ErrorAction SilentlyContinue)) {
    Write-Warning "Azure CLI is not installed. Attempting to install using winget..."
    try {
        winget install --id Microsoft.AzureCLI -e --accept-package-agreements --accept-source-agreements
    } catch {
        Write-Error "Failed to install Azure CLI via winget. Please install manually from https://aka.ms/installazurecliwindows"
        exit 1
    }

    if (-not (Get-Command "az" -ErrorAction SilentlyContinue)) {
        Write-Error "Azure CLI installation via winget failed. Please install manually."
        exit 1
    }

    Write-Host "Azure CLI installed successfully."
}

# Check for OpenSSL
$opensslPath = Get-Command "openssl" -ErrorAction SilentlyContinue
if (-not $opensslPath) {
    Write-Host "OpenSSL not found. Attempting to download and install it silently..."

    $opensslInstallerUrl = "https://slproweb.com/download/Win64OpenSSL_Light-3_5_0.exe"
    $opensslInstallerPath = "$env:TEMP\Win64OpenSSL_Light-3_5_0.exe"

    try {
        Invoke-WebRequest -Uri $opensslInstallerUrl -OutFile $opensslInstallerPath -UseBasicParsing
    } catch {
        Write-Error "Failed to download OpenSSL installer. Please check your internet connection or download the installer manually from https://slproweb.com/products/Win32OpenSSL.html"
        exit 1
    }

    # Run the installer silently
    Start-Process -FilePath $opensslInstallerPath -ArgumentList "/silent", "/verysilent", "/norestart" -Wait

    # Add OpenSSL to PATH for the current session
    $opensslInstallDir = "C:\Program Files\OpenSSL-Win64\bin"
    if (Test-Path $opensslInstallDir) {
        $env:Path += ";$opensslInstallDir"
    } else {
        Write-Error "OpenSSL installation directory not found. Please ensure OpenSSL is installed correctly."
        exit 1
    }

    # Verify installation
    $opensslPath = Get-Command "openssl" -ErrorAction SilentlyContinue
    if (-not $opensslPath) {
        Write-Error "OpenSSL installation failed. Please install it manually from https://slproweb.com/products/Win32OpenSSL.html"
        exit 1
    }
}

Write-Host "`nLogging into Azure..."
az login --tenant $TenantId | Out-Null
az account set --subscription $SubscriptionId

Write-Host "`nRetrieving decryption key..."
$key = az keyvault secret show `
  --vault-name $VaultName `
  --name $SecretName `
  --query "value" -o tsv

if (-not $key) {
    Write-Error "Failed to retrieve key."
    exit 1
}

# Function: download and decrypt a .env file
function Download-And-Decrypt {
    param (
        [string]$blobName,
        [string]$b64File,
        [string]$encFile,
        [string]$outFile
    )

    Write-Host "`nDownloading $blobName from Azure..."
    az storage blob download `
      --account-name $StorageAccount `
      --container-name $EncContainer `
      --name $blobName `
      --file $b64File `
      --auth-mode login `
      --only-show-errors | Out-Null

    if (-not (Test-Path $b64File)) {
        Write-Error "Failed to download $blobName"
        exit 1
    }

    Write-Host "Decoding base64 to $encFile..."
    certutil -decode $b64File $encFile | Out-Null

    Write-Host "Decrypting to $outFile..."
    openssl enc -aes-256-cbc -pbkdf2 -d `
      -in $encFile `
      -out $outFile `
      -k $key
}

function Ensure-EnvDefault {
    param (
        [string]$file,
        [string]$name,
        [string]$value
    )

    if (-not (Test-Path $file)) {
        Write-Error "Cannot update missing env file: $file"
        exit 1
    }

    $pattern = "^\s*$([regex]::Escape($name))="
    if (-not (Select-String -Path $file -Pattern $pattern -Quiet)) {
        Add-Content -Path $file -Value "$name=$value"
        Write-Host "Added local default $name=$value to $file"
    }
}

Download-And-Decrypt -blobName $BlobParentEnv -b64File $TmpParentB64 -encFile $TmpParentEnc -outFile $OutParentEnv
Write-Host "Parent env decrypted to $OutParentEnv"

Download-And-Decrypt -blobName $BlobChildEnv -b64File $TmpChildB64 -encFile $TmpChildEnc -outFile $OutChildEnv
Write-Host "Child env decrypted to $OutChildEnv"

# Local Docker Compose uses a standalone, non-TLS Redis container.
# These defaults keep Symfony's cluster-aware Redis client config from requiring
# AKS/Azure Redis settings in developer environments.
Ensure-EnvDefault -file $OutChildEnv -name "REDIS_CLUSTER_ENABLED" -value "0"
Ensure-EnvDefault -file $OutChildEnv -name "REDIS_TLS_ENABLED" -value "0"
Ensure-EnvDefault -file $OutChildEnv -name "REDIS_TLS_VERIFY_PEER" -value "0"
Ensure-EnvDefault -file $OutChildEnv -name "REDIS_TLS_VERIFY_PEER_NAME" -value "0"

Write-Host "`nDownloading SQL dumps..."

az storage blob download `
  --account-name $StorageAccount `
  --container-name $SqlContainer `
  --name "eacv3_migrated_dump.sql" `
  --file $SqlChildLocal `
  --auth-mode login `
  --only-show-errors | Out-Null

az storage blob download `
  --account-name $StorageAccount `
  --container-name $SqlContainer `
  --name "eacv3parent_dump.sql" `
  --file $SqlParentLocal `
  --auth-mode login `
  --only-show-errors | Out-Null

Write-Host "SQL dumps saved:"
Write-Host "  $SqlChildLocal"
Write-Host "  $SqlParentLocal"

Write-Host "`nCleaning up temp files..."
Remove-Item -Force $TmpParentB64, $TmpChildB64, $TmpParentEnc, $TmpChildEnc

Write-Host "`nAll tasks completed successfully."
