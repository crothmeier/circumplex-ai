# Circumplex‑AI Home‑Lab K3s Runbook
Generated: 2025-04-23

## Node Inventory
| Node | Role | Env | GPU | Storage |
|------|------|-----|-----|---------|
| node1 (phx‑ai01) | control‑plane + worker | Ubuntu 22.04 | — | NVMe SSD |
| node2 (phx‑ai02) | GPU worker | Ubuntu 22.04 | RTX A2000 | HDD |
| node3 (lz‑pf4wcbn1) | GPU worker (dev) | WSL2 Ubuntu 22.04 | RTX A2000 | VHDX |

## 1 GPU Bring‑Up
1. Install NVIDIA driver + `nvidia‑container‑toolkit`.  
2. Ensure containerd runtime entry exists (`grep nvidia ...config.toml`).  
3. Confirm `RuntimeClass/nvidia` or apply manifests/runtimeclass-nvidia.yaml.  
4. Run `scripts/nvdp_install.sh`.  
5. `kubectl apply -f manifests/gpu-smoke.yaml` → expect `nvidia-smi` output.

*WSL2*: If NVML errors, pass env `FAIL_ON_INIT_ERROR=false` to plugin.

## 2 Traefik Dual‑Stack
`helm upgrade -i traefik traefik/traefik -n kube-system -f charts/traefik/traefik-values.yaml`

Verify `.spec.ipFamilies: [IPv4, IPv6]` and scrape `/metrics` on 9100.

## 3 Storage
* **Longhorn** deferred (WSL2 unsupported, write‑amp).  
* **Local‑Path** in use; back up with Velero Restic to MinIO.

## 4 Post‑Reboot Checklist
1. Auto‑start WSL2 distro + k3s.  
2. Check GPU capacity `kubectl describe node node2`.  
3. Validate Traefik LoadBalancer dual IP.  
4. Ensure backups completed: `velero backup get`.

—
