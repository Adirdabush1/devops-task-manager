#!/usr/bin/env bash
# Local, FREE end-to-end test on minikube (no AWS cost).
set -euo pipefail
cd "$(dirname "$0")/.."

minikube start --driver=docker
minikube addons enable ingress

# Build the app images directly inside minikube's docker so IfNotPresent finds them.
eval "$(minikube docker-env)"
docker build -t task-manager-backend:latest  ./backend
docker build -t task-manager-frontend:latest ./frontend
eval "$(minikube docker-env -u)"

kubectl apply -f k8s/

# Point BACKEND_URL at the minikube ingress IP, then restart the frontend.
IP="$(minikube ip)"
kubectl -n task-manager set env deployment/frontend "BACKEND_URL=http://$IP"
kubectl -n task-manager rollout restart deployment/frontend

echo
echo "Wait for pods:  kubectl -n task-manager get pods -w"
echo "Open the app :  http://$IP/"
echo "(Ingress addon may take ~1 min to get an address.)"
