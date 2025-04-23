#!/usr/bin/env bash
set -euo pipefail
kubectl create ns gpu-system --dry-run=client -o yaml | kubectl apply -f -
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update
helm upgrade --install nvdp nvdp/nvidia-device-plugin       --namespace gpu-system       --version 0.14.3       --set runtimeClassName=nvidia       --set tolerations[0].key=gpu       --set tolerations[0].operator=Equal       --set tolerations[0].value=true       --set tolerations[0].effect=NoSchedule       --set nodeSelector.gpu=true
