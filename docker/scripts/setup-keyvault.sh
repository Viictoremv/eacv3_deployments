#!/bin/bash
set -e
az login --use-device-code
az keyvault secret show --name "APP_SECRET" --vault-name "kv-dev-eas" --query value -o tsv > /tmp/.env.secret
