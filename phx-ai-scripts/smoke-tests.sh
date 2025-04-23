#!/bin/bash
# Smoke Test Script for phx-ai-cluster
set -e
echo "PHX AI Cluster Smoke Tests"
echo "=========================="
echo

echo "1. NVIDIA GPU Plugin and CUDA Tests"
echo "----------------------------------"
echo "🔍 Checking NVIDIA Device Plugin pods..."
kubectl get pods -n nvidia-device-plugin

echo "🔍 Checking available GPUs in the cluster..."
kubectl get nodes -o json | jq '.items[] | {name:.metadata.name, gpus:.status.capacity["nvidia.com/gpu"]}'

echo "🔍 Running CUDA vector-add test pod..."
kubectl apply -f ~/phx-ai-cluster/manifests/tests/cuda-test-pod.yaml
sleep 10
kubectl get pod cuda-vectoradd
kubectl logs cuda-vectoradd
kubectl delete pod cuda-vectoradd

echo "🔍 Checking DCGM Exporter..."
DCGM_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=dcgm-exporter -o name | head -n 1)
if [ -n "$DCGM_POD" ]; then
  echo "✅ DCGM Exporter running"
else
  echo "❌ DCGM Exporter not found"
fi
echo

echo "2. Traefik and MetalLB Tests"
echo "--------------------------"
kubectl get pods -n traefik
kubectl get svc -n traefik -o wide
echo
kubectl get pods -n metallb-system -l app.kubernetes.io/component=speaker
kubectl get l2advertisement -n metallb-system
kubectl get bgpadvertisement -n metallb-system
kubectl get bgppeer -n metallb-system -o wide
echo

echo "3. kube-proxy nftables Check"
echo "-------------------------"
PROXY_POD=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy -o name | head -n 1)
kubectl logs $PROXY_POD -n kube-system | grep -i 'Using nftables' || echo "kube-proxy not in nftables mode"
echo

echo "4. Monitoring Stack Verification"
echo "-----------------------"
kubectl get pods -n monitoring
kubectl get servicemonitor -n monitoring
echo "🔗 Access Grafana: kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80"
echo "=========================="
echo "Smoke tests completed."
