#!/bin/bash

RESOURCE_GROUP="eac-aks"
STORAGE_ACCOUNT="saeaceasv3"

echo "📥 Fetching existing firewall rules..."
EXISTING_RULES=$(az storage account network-rule list \
  --resource-group "$RESOURCE_GROUP" \
  --account-name "$STORAGE_ACCOUNT" \
  --query "ipRules[].ipAddressOrRange" -o tsv)

# Function to check if an IP is already whitelisted
ip_exists() {
  echo "$EXISTING_RULES" | grep -Fxq "$1"
}

echo "🌐 Fetching GitHub Actions IPs..."
GITHUB_IPS=$(curl -s https://api.github.com/meta | jq -r '.actions[]')

# Collect IPs to add
IPS_TO_ADD=()

for ip in $GITHUB_IPS; do

  # Handle /30 and /31 CIDRs
  if echo "$ip" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}/(30|31)$'; then
    echo "🔀 Splitting CIDR $ip"

    base=$(echo "$ip" | cut -d/ -f1)
    cidr=$(echo "$ip" | cut -d/ -f2)
    IFS='.' read -r a b c d <<< "$base"

    block_size=$((1 << (32 - cidr)))
    start=$((d & ~(block_size - 1)))
    end=$((start + block_size - 1))

    for i in $(seq $start $end); do
      # Skip network/broadcast IPs for /30 only
      if [[ "$cidr" == "30" && ( "$i" == "$start" || "$i" == "$end" ) ]]; then
        continue
      fi

      ip32="$a.$b.$c.$i"
      if ! ip_exists "$ip32"; then
        IPS_TO_ADD+=("$ip32")
        echo "✅ Queued $ip32"
      else
        echo "⏭️ Already whitelisted: $ip32"
      fi
    done
    continue
  fi

  # Skip anything that’s not valid IPv4 or IPv4/CIDR
  if ! echo "$ip" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}(/(3[2]|[1-2]?[0-9])?)?$'; then
    echo "❌ Skipping invalid or IPv6 IP: $ip"
    continue
  fi

  # Skip raw /30 or /31 if not parsed above (defensive)
  if [[ "$ip" == */30 || "$ip" == */31 ]]; then
    echo "⚠️ Skipping unmatched CIDR: $ip"
    continue
  fi

  # Normal /32 or CIDR
  if ! ip_exists "$ip"; then
    IPS_TO_ADD+=("$ip")
    echo "✅ Queued $ip"
  else
    echo "⏭️ Already whitelisted: $ip"
  fi
done

echo "🧮 Total new IPs to add: ${#IPS_TO_ADD[@]}"

for ip in "${IPS_TO_ADD[@]}"; do
  echo "➕ Adding $ip"
  az storage account network-rule add \
    --resource-group "$RESOURCE_GROUP" \
    --account-name "$STORAGE_ACCOUNT" \
    --ip-address "$ip" \
    --only-show-errors > /dev/null 2>&1 \
    || echo "⚠️ Failed to add $ip"
done

echo "✅ All done"
