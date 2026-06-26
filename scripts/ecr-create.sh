#!/usr/bin/env bash
# Part A: create the two private ECR repositories (idempotent).
set -euo pipefail
cd "$(dirname "$0")"
source ./env.sh

for repo in "$BACKEND_REPO" "$FRONTEND_REPO"; do
  if aws ecr describe-repositories --repository-names "$repo" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "ECR repo already exists: $repo"
  else
    aws ecr create-repository --repository-name "$repo" --region "$AWS_REGION" \
      --image-scanning-configuration scanOnPush=false >/dev/null
    echo "Created ECR repo: $repo"
  fi
done

echo "Registry: $ECR_REGISTRY"
aws ecr describe-repositories --region "$AWS_REGION" \
  --query 'repositories[].repositoryUri' --output table
