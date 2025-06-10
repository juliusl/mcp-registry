#!/bin/bash

set -e

# Required values
registry_db="mongo"
registry_image=""
registry_db_image=""
env="test"
secret_name=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --env)
        env="$2"
        shift 2
        ;;
        --github-secret-name)
        secret_name="$2"
        shift 2
        ;;
        --*)
    esac
done

# Check if secret_name is set and output some useful information about the expectations
if [[ -z "$secret_name" ]]; then
    echo "Value for --github-secret-name is required"
    echo "Expecting a secret to be deployed in the following format:"
    cat << EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: <your-secret-name-here>
  namespace: io.github.mcp
type: Opaque
data:
  MCP_REGISTRY_GITHUB_CLIENT_SECRET: <base64 of 'MCP_REGISTRY_GITHUB_CLIENT_SECRET'>
  MCP_REGISTRY_GITHUB_CLIENT_ID: <base64 of 'MCP_REGISTRY_GITHUB_CLIENT_ID'>
EOF
    exit 1
fi

echo "Current template for mcp-registry deployment"
helm template mcp-registry . \
    -f ./deploy/values.yaml \
    -f "./deploy/values.$env.yaml" \
    --set registry.db="$registry_db" \
    --set registry.image="$registry_image" \
    --set db.mongo.image="$registry_db_image" \
    --set registry.github_secret_name="$secret_name" \
    --debug

echo "Deploying App"
helm install mcp-registry . --create-namespace --namespace io.github.mcp \
    -f ./deploy/values.yaml \
    -f "./deploy/values.$env.yaml" \
    --set registry.db="$registry_db" \
    --set registry.image="$registry_image" \
    --set db.mongo.image="$registry_db_image" \
    --set registry.github_secret_name="$secret_name"