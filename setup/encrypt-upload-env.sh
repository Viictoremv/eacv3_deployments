#!/bin/bash

# Ensure that the project root path is set correctly
PROJECT_ROOT=$(pwd)

set -e

# Constants
TENANT_ID="ee0f492d-f5b9-4631-af0b-4fa28da42b47"
SUBSCRIPTION_ID="207f196d-bd00-4e7e-a3fd-ddcd24135477"
KEYVAULT_NAME="kv-aks-eac-eus"
SECRET_NAME="easv3parent-decryption-key"
STORAGE_ACCOUNT="saeaceasv3"     # ⬅️ Replace with your actual storage account name
STORAGE_CONTAINER="encrypted-env"          # ⬅️ Replace with your container name
LOCAL_ENV_FILE_PARENT="$PROJECT_ROOT/env/parent/.env.local.override"
ENC_FILE_PARENT="$PROJECT_ROOT/env/parent/.env_parent.enc"
ENC_B64_FILE_PARENT="$PROJECT_ROOT/env/parent/.env_parent.enc.b64"
LOCAL_ENV_FILE_CHILD="$PROJECT_ROOT/env/child/.env.local.override"
ENC_FILE_CHILD="$PROJECT_ROOT/env/child/.env_child.enc"
ENC_B64_FILE_CHILD="$PROJECT_ROOT/env/child/.env_child.enc.b64"

echo "🔍 Checking for required tools..."
REQUIRED_TOOLS=("az" "openssl" "base64")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v $tool &> /dev/null; then
        echo "⚠️ $tool not found. Installing via Homebrew..."
        brew install $tool
    else
        echo "✅ $tool is installed."
    fi
done

echo ""
echo "🔐 Running az login (skip if already logged in)..."
az login --tenant "$TENANT_ID" >/dev/null
az account set --subscription "$SUBSCRIPTION_ID"

echo ""
echo "🔑 Fetching decryption key from Azure Key Vault..."
DECRYPTION_KEY=$(az keyvault secret show \
  --vault-name "$KEYVAULT_NAME" \
  --name "$SECRET_NAME" \
  --query value \
  -o tsv)

if [ -z "$DECRYPTION_KEY" ]; then
    echo "❌ Failed to retrieve decryption key from Key Vault"
    exit 1
fi

echo ""
echo "🔒 Encrypting $LOCAL_ENV_FILE_PARENT to $ENC_FILE_PARENT..."
if [ ! -f "$LOCAL_ENV_FILE_PARENT" ]; then
  echo "❌ File $LOCAL_ENV_FILE_PARENT not found!"
  exit 1
fi

openssl enc -aes-256-cbc -salt -pbkdf2 \
  -in "$LOCAL_ENV_FILE_PARENT" \
  -out "$ENC_FILE_PARENT" \
  -pass pass:"$DECRYPTION_KEY"

echo ""
echo "🔄 Encoding to base64..."
# Use compatible base64 syntax for both macOS/Linux and Windows Git Bash
if base64 --help 2>&1 | grep -q "\-\-input"; then
  base64 -i "$ENC_FILE_PARENT" -o "$ENC_B64_FILE_PARENT"
else
  base64 "$ENC_FILE_PARENT" > "$ENC_B64_FILE_PARENT"
fi

echo ""
echo "☁️ Uploading $ENC_B64_FILE_PARENT to Azure Blob Storage..."
az storage blob upload \
  --account-name "$STORAGE_ACCOUNT" \
  --container-name "$STORAGE_CONTAINER" \
  --name "$(basename "$ENC_B64_FILE_PARENT")" \
  --file "$ENC_B64_FILE_PARENT" \
  --auth-mode login \
  --overwrite true \
  --only-show-errors


echo ""
echo "✅ Upload complete: $ENC_B64_FILE_PARENT"


echo ""
echo "🔒 Encrypting $LOCAL_ENV_FILE_CHILD to $ENC_FILE_CHILD..."
if [ ! -f "$LOCAL_ENV_FILE_CHILD" ]; then
  echo "❌ File $LOCAL_ENV_FILE_CHILD not found!"
  exit 1
fi

openssl enc -aes-256-cbc -salt -pbkdf2 \
  -in "$LOCAL_ENV_FILE_CHILD" \
  -out "$ENC_FILE_CHILD" \
  -pass pass:"$DECRYPTION_KEY"

echo ""
echo "🔄 Encoding to base64..."
# Use compatible base64 syntax for both macOS/Linux and Windows Git Bash
if base64 --help 2>&1 | grep -q "\-\-input"; then
  base64 -i "$ENC_FILE_CHILD" -o "$ENC_B64_FILE_CHILD"
else
  base64 "$ENC_FILE_CHILD" > "$ENC_B64_FILE_CHILD"
fi

echo ""
echo "☁️ Uploading $ENC_B64_FILE_CHILD to Azure Blob Storage..."
az storage blob upload \
  --account-name "$STORAGE_ACCOUNT" \
  --container-name "$STORAGE_CONTAINER" \
  --name "$(basename "$ENC_B64_FILE_CHILD")" \
  --file "$ENC_B64_FILE_CHILD" \
  --auth-mode login \
  --overwrite true \
  --only-show-errors


echo ""
echo "✅ Upload complete: $ENC_B64_FILE_CHILD"
