#!/usr/bin/env bash
# Manually build both images with a version tag and push to ECR.
# Useful to (a) verify ECR works (Part A), and (b) seed images before the first EKS deploy.
# Usage: ./scripts/build-push.sh [TAG]   (default tag: v-manual)
set -euo pipefail
cd "$(dirname "$0")"
source ./env.sh
TAG="${1:-v-manual}"
cd ..

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR_REGISTRY"

docker build -t "$ECR_REGISTRY/$BACKEND_REPO:$TAG"  -t "$ECR_REGISTRY/$BACKEND_REPO:latest"  ./backend
docker build -t "$ECR_REGISTRY/$FRONTEND_REPO:$TAG" -t "$ECR_REGISTRY/$FRONTEND_REPO:latest" ./frontend

docker push "$ECR_REGISTRY/$BACKEND_REPO:$TAG";  docker push "$ECR_REGISTRY/$BACKEND_REPO:latest"
docker push "$ECR_REGISTRY/$FRONTEND_REPO:$TAG"; docker push "$ECR_REGISTRY/$FRONTEND_REPO:latest"
echo "Pushed $TAG and latest to $ECR_REGISTRY"
