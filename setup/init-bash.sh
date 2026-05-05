#!/bin/bash

set -e

PROJECT_ROOT=$(pwd)

# Azure config
VAULT_NAME="kv-aks-eac-eus"
SECRET_NAME="easv3parent-decryption-key"
STORAGE_ACCOUNT="saeaceasv3"
ENC_CONTAINER="encrypted-env"
SQL_CONTAINER="k8sbuildassets"
TENANT_ID="ee0f492d-f5b9-4631-af0b-4fa28da42b47"
SUBSCRIPTION_ID="207f196d-bd00-4e7e-a3fd-ddcd24135477"

# Paths
BLOB_PARENT_ENV=".env_parent.enc.b64"
BLOB_CHILD_ENV=".env_child.enc.b64"

TMP_PARENT_ENC="$PROJECT_ROOT/.env_parent.enc"
TMP_CHILD_ENC="$PROJECT_ROOT/.env_child.enc"
TMP_PARENT_B64="$PROJECT_ROOT/.env_parent.enc.b64"
TMP_CHILD_B64="$PROJECT_ROOT/.env_child.enc.b64"

OUT_PARENT_ENV="$PROJECT_ROOT/env/parent/.env.local.override"
OUT_CHILD_ENV="$PROJECT_ROOT/env/child/.env.local.override"

# SQL destinations
SQL_CHILD_LOCAL="$PROJECT_ROOT/docker/initdb/child/00-childdbload.sql"
SQL_PARENT_LOCAL="$PROJECT_ROOT/docker/initdb/parent/00-parentdbload.sql"

echo "🔍 Verifying dependencies..."
for tool in az openssl base64; do
  if ! command -v "$tool" >/dev/null; then
    echo "❌ $tool is missing. Please install it."
    exit 1
  fi
done

echo ""
echo "🔐 Azure login and subscription setup..."
az login --tenant "$TENANT_ID" --only-show-errors >/dev/null
az account set --subscription "$SUBSCRIPTION_ID"

echo ""
echo "🔑 Retrieving decryption key..."
KEY=$(az keyvault secret show --vault-name "$VAULT_NAME" --name "$SECRET_NAME" --query "value" -o tsv)

if [[ -z "$KEY" ]]; then
  echo "❌ Failed to retrieve decryption key."
  exit 1
fi

ensure_env_default() {
  local file="$1"
  local name="$2"
  local value="$3"

  if [[ ! -f "$file" ]]; then
    echo "❌ Cannot update missing env file: $file"
    exit 1
  fi

  if ! grep -Eq "^[[:space:]]*${name}=" "$file"; then
    printf '\n%s=%s\n' "$name" "$value" >> "$file"
    echo "✅ Added local default $name=$value to $file"
  fi
}

echo ""
echo "📥 Downloading and decrypting parent env file..."
az storage blob download \
  --account-name "$STORAGE_ACCOUNT" \
  --container-name "$ENC_CONTAINER" \
  --name "$BLOB_PARENT_ENV" \
  --file "$TMP_PARENT_B64" \
  --auth-mode login --output none

base64 -d -i "$TMP_PARENT_B64" -o "$TMP_PARENT_ENC"
openssl enc -aes-256-cbc -pbkdf2 -d -in "$TMP_PARENT_ENC" -out "$OUT_PARENT_ENV" -k "$KEY"

echo "✅ Parent env decrypted to $OUT_PARENT_ENV"

echo ""
echo "📥 Downloading and decrypting child env file..."
az storage blob download \
  --account-name "$STORAGE_ACCOUNT" \
  --container-name "$ENC_CONTAINER" \
  --name "$BLOB_CHILD_ENV" \
  --file "$TMP_CHILD_B64" \
  --auth-mode login --output none

base64 -d -i "$TMP_CHILD_B64" -o "$TMP_CHILD_ENC"
openssl enc -aes-256-cbc -pbkdf2 -d -in "$TMP_CHILD_ENC" -out "$OUT_CHILD_ENV" -k "$KEY"

echo "✅ Child env decrypted to $OUT_CHILD_ENV"

# Local Docker Compose uses a standalone, non-TLS Redis container.
# These defaults keep Symfony's cluster-aware Redis client config from requiring
# AKS/Azure Redis settings in developer environments.
ensure_env_default "$OUT_CHILD_ENV" "REDIS_CLUSTER_ENABLED" "0"
ensure_env_default "$OUT_CHILD_ENV" "REDIS_TLS_ENABLED" "0"
ensure_env_default "$OUT_CHILD_ENV" "REDIS_TLS_VERIFY_PEER" "0"
ensure_env_default "$OUT_CHILD_ENV" "REDIS_TLS_VERIFY_PEER_NAME" "0"

echo ""
echo "📥 Downloading SQL dumps from Azure..."
az storage blob download \
  --account-name "$STORAGE_ACCOUNT" \
  --container-name "$SQL_CONTAINER" \
  --name "eacv3_migrated_dump.sql" \
  --file "$SQL_CHILD_LOCAL" \
  --auth-mode login --output none

az storage blob download \
  --account-name "$STORAGE_ACCOUNT" \
  --container-name "$SQL_CONTAINER" \
  --name "eacv3parent_dump.sql" \
  --file "$SQL_PARENT_LOCAL" \
  --auth-mode login --output none

echo "✅ SQL dump downloaded to:"
echo "   - $SQL_CHILD_LOCAL"
echo "   - $SQL_PARENT_LOCAL"

echo ""
echo "🧹 Cleaning up..."
rm -f "$TMP_PARENT_B64" "$TMP_PARENT_ENC" "$TMP_CHILD_B64" "$TMP_CHILD_ENC"

echo "✅ All tasks completed."
