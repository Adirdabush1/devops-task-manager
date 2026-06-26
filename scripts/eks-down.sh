#!/usr/bin/env bash
# Tear everything down to stop billing. Run AFTER screenshots + a green pipeline run.
set -euo pipefail
cd "$(dirname "$0")/.."
source ./scripts/env.sh

echo ">> Deleting the ingress LoadBalancer first (so the ELB is released cleanly)..."
helm uninstall ingress-nginx -n ingress-nginx || true
kubectl delete -f k8s/ --ignore-not-found || true

echo ">> Deleting the EKS cluster (also removes its VPC, nodes, EBS PVs)..."
eksctl delete cluster -f eks/cluster.yaml --disable-nodegroup-eviction

echo
echo ">> VERIFY nothing is still billing in the AWS console / CLI:"
echo "   - Load Balancers:"
aws elbv2 describe-load-balancers --region "$AWS_REGION" --query 'LoadBalancers[].LoadBalancerName' --output text 2>/dev/null || true
aws elb  describe-load-balancers --region "$AWS_REGION" --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text 2>/dev/null || true
echo "   - Orphaned EBS volumes (state=available):"
aws ec2 describe-volumes --region "$AWS_REGION" --filters Name=status,Values=available \
  --query 'Volumes[].VolumeId' --output text 2>/dev/null || true
echo
echo "If any LB or volume is listed above, delete it manually. ECR repos are kept (cents/mo)."
