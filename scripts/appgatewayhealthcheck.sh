#!/bin/bash
# ------------------------------------------------------------
# Azure App Gateway Health Monitor for AKS Backends
# Author: Ben Rubert use-case adapted
# ------------------------------------------------------------

GATEWAY="ingress-appgateway"
RG="MC_k8s_eac_eas"

echo "🔍 Monitoring backend health for $GATEWAY in resource group $RG"
echo "Press Ctrl+C to stop."

while true; do
  clear
  echo "⏱  $(date)"
  echo "------------------------------------------------------------"
  az network application-gateway show-backend-health \
    --name "$GATEWAY" \
    --resource-group "$RG" \
    --query "backendAddressPools[].backendHttpSettingsCollection[].servers[].{Address:address,Health:health,Reason:healthProbeLog}" \
    -o tsv |
  while IFS=$'\t' read -r address health reason; do
    if [[ "$health" == "Healthy" ]]; then
      printf "\033[32m%-15s %-10s\033[0m\n" "$address" "$health"
    else
      printf "\033[31m%-15s %-10s\033[0m %s\n" "$address" "$health" "$reason"
    fi
  done
  echo "------------------------------------------------------------"
  sleep 60
done