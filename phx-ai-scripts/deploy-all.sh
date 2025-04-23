#!/bin/bash
# Deployment script for phx-ai-cluster
set -e

BASEDIR=~/phx-ai-cluster

# 1. Install NVIDIA Device Plugin
echo "Installing NVIDIA Device Plugin..."
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update
helm upgrade -i nvdp nvdp/nvidia-device-plugin \
  --namespace nvidia-device-plugin \
  --create-namespace \
  --version 0.17.1 \
  -f $BASEDIR/charts/nvidia/nvidia-device-plugin-values.yaml

# 2. Install MetalLB
echo "Installing MetalLB..."
kubectl apply -f $BASEDIR/manifests/metallb/namespace.yaml || true
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install metallb metallb/metallb \
  --namespace metallb-system \
  -f $BASEDIR/charts/metallb/metallb-values.yaml

# Wait for MetalLB to be ready
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/part-of=metallb \
  --timeout=90s

# Deploy MetalLB configuration
echo "Deploying MetalLB Configuration..."
kubectl apply -f $BASEDIR/manifests/metallb/ipaddresspool.yaml
kubectl apply -f $BASEDIR/manifests/metallb/bfd-profile.yaml
kubectl apply -f $BASEDIR/manifests/metallb/bgppeer.yaml
kubectl apply -f $BASEDIR/manifests/metallb/bgpadvertisement.yaml
kubectl apply -f $BASEDIR/manifests/metallb/l2advertisement.yaml

# 3. Install Traefik
echo "Installing Traefik..."
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik-crds traefik/traefik-crds -n traefik --create-namespace
helm install traefik traefik/traefik -n traefik \
  -f $BASEDIR/charts/traefik/traefik-v3-values.yaml \
  --skip-crds

# 4. Install Prometheus Stack
echo "Installing Prometheus Stack..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f $BASEDIR/charts/observability/prometheus-values.yaml

# Apply ServiceMonitors
echo "Applying ServiceMonitors..."
kubectl apply -f $BASEDIR/manifests/monitoring/traefik-servicemonitor.yaml
kubectl apply -f $BASEDIR/manifests/monitoring/longhorn-servicemonitor.yaml

# 5. Install DCGM Exporter
echo "Installing DCGM Exporter..."
helm repo add gpu-helm-charts https://nvidia.github.io/dcgm-exporter/helm-charts
helm repo update
helm install dcgm-exporter gpu-helm-charts/dcgm-exporter \
  --namespace monitoring \
  -f $BASEDIR/charts/observability/dcgm-exporter-values.yaml

# 6. Configure nftables for kube-proxy (optional)
echo "Would you like to migrate kube-proxy to nftables? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo "Configuring nftables..."
  sudo mkdir -p /etc/systemd/system/k3s.service.d/
  sudo cp $BASEDIR/systemd/k3s/nftables.conf /etc/systemd/system/k3s.service.d/
  sudo systemctl daemon-reload
  sudo systemctl restart k3s
fi

echo "Deployment complete!"
echo "Run $BASEDIR/scripts/smoke-tests.sh to verify the deployment."
