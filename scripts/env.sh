#!/usr/bin/env bash
# Shared settings sourced by the other scripts. Override via your shell environment.
export AWS_REGION="${AWS_REGION:-us-east-1}"
export CLUSTER_NAME="${CLUSTER_NAME:-task-manager}"
export K8S_NAMESPACE="${K8S_NAMESPACE:-task-manager}"
export BACKEND_REPO="${BACKEND_REPO:-task-manager-backend}"
export FRONTEND_REPO="${FRONTEND_REPO:-task-manager-frontend}"

# Resolved automatically from your AWS credentials.
AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)"
export AWS_ACCOUNT_ID
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
