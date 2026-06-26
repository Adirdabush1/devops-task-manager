#!/usr/bin/env bash
# Bring up the cost-minimized EKS cluster and deploy the app.
# Run this ONLY when you are ready to capture screenshots + run the pipeline.
set -euo pipefail
cd "$(dirname "$0")/.."
source ./scripts/env.sh

echo ">> Ensuring ECR repos exist and images are pushed (tag: latest)..."
./scripts/ecr-create.sh
./scripts/build-push.sh latest

echo ">> Creating EKS cluster (this takes ~15-20 min)..."
eksctl create cluster -f eks/cluster.yaml
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

echo ">> Making gp3 the default StorageClass..."
kubectl apply -f eks/gp3-storageclass.yaml || true

echo ">> Installing ingress-nginx (creates ONE LoadBalancer)..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer

echo ">> Applying app manifests..."
kubectl apply -f k8s/

echo ">> Pointing Deployments at the ECR images (tag: latest)..."
kubectl -n "$K8S_NAMESPACE" set image deployment/backend  backend="$ECR_REGISTRY/$BACKEND_REPO:latest"
kubectl -n "$K8S_NAMESPACE" set image deployment/frontend frontend="$ECR_REGISTRY/$FRONTEND_REPO:latest"

echo ">> Waiting for the ingress LoadBalancer hostname..."
for i in $(seq 1 30); do
  LB="$(kubectl -n ingress-nginx get svc ingress-nginx-controller \
        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
  [ -n "$LB" ] && break
  sleep 10
done

if [ -n "${LB:-}" ]; then
  echo ">> Setting BACKEND_URL=http://$LB and restarting frontend..."
  kubectl -n "$K8S_NAMESPACE" set env deployment/frontend "BACKEND_URL=http://$LB"
  kubectl -n "$K8S_NAMESPACE" rollout restart deployment/frontend
  echo
  echo "App URL: http://$LB/"
else
  echo "LoadBalancer hostname not ready yet. Get it later with:"
  echo "  kubectl -n ingress-nginx get svc ingress-nginx-controller"
fi

echo
echo "Status: kubectl -n $K8S_NAMESPACE get pods,svc,ingress"
echo "REMEMBER: run the Jenkins pipeline + take all screenshots, THEN ./scripts/eks-down.sh"
