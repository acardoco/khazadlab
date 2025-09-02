#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-/root/master.env}"
[[ -f "$ENV_FILE" ]] || { echo "No existe $ENV_FILE"; exit 1; }
sed -i 's/\r$//' "$ENV_FILE" 2>/dev/null || true
set -a; . "$ENV_FILE"; set +a

need(){ [[ -n "${!1:-}" ]] || { echo "Falta $1 en $ENV_FILE"; exit 1; }; }

echo "==> Pre-flight"
need RENDERER; need IFACE_NAME; need STATIC_IP_CIDR; need GATEWAY
need WIFI_SSID; need WIFI_PSK
need NODE_IP; : "${NODE_EXTERNAL_IP:=}"
: "${UPSTREAM_DNS:=1.1.1.1 9.9.9.9}"

if [[ "${K3S_INIT:-false}" != "true" ]]; then
  need K3S_JOIN_URL; need K3S_TOKEN
fi

echo "==> Paquetes base"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl ufw open-iscsi nfs-common ca-certificates jq \
                   ddclient systemd-resolved

echo "==> Swap off"
swapoff -a || true
sed -ri '/\sswap\s/s/^/#/' /etc/fstab || true

echo "==> UFW (masters: 22,6443,2379-2380,10250,8472,NodePorts,80/443,9100)"
if [[ "${ENABLE_UFW:-true}" == "true" ]]; then
  ufw allow 22/tcp || true
  ufw allow 6443/tcp || true
  ufw allow 2379:2380/tcp || true     # etcd peer & client
  ufw allow 10250/tcp || true
  ufw allow 8472/udp || true
  ufw allow 30000:32767/tcp || true
  ufw allow 30000:32767/udp || true
  ufw allow 80/tcp || true
  ufw allow 443/tcp || true
  ufw allow 9100/tcp || true
  yes | ufw enable || true
fi

echo "==> Netplan (${RENDERER}) Wi-Fi estático (${IFACE_NAME})"
cat >/etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  renderer: ${RENDERER}
  wifis:
    ${IFACE_NAME}:
      dhcp4: no
      dhcp6: no
      addresses: [${STATIC_IP_CIDR}]
      routes:
        - to: default
          via: ${GATEWAY}
      access-points:
        "${WIFI_SSID}":
          password: "${WIFI_PSK}"
EOF

echo "==> netplan apply (si estás por SSH puede cortarse)"
netplan apply || true

echo "==> Upstreams para systemd-resolved (para pulls antes de AdGuard)"
mkdir -p /etc/systemd/resolved.conf.d
cat >/etc/systemd/resolved.conf.d/99-upstreams.conf <<EOF
[Resolve]
DNS=${UPSTREAM_DNS}
FallbackDNS=
Domains=~.
EOF
systemctl restart systemd-resolved || true
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf || true

# Detectar IP pública si no se pasó por env
if [[ -z "${NODE_EXTERNAL_IP}" ]]; then
  NODE_EXTERNAL_IP="$(curl -fsSL https://api.ipify.org || true)"
fi

echo "==> Config k3s server en /etc/rancher/k3s/config.yaml"
mkdir -p /etc/rancher/k3s
{
  # Deshabilitar componentes
  echo "disable:"
  [[ "${DISABLE_SERVICELB:-true}" == "true" ]] && echo "  - servicelb"
  [[ "${DISABLE_TRAEFIK:-false}" == "true" ]] && echo "  - traefik"

  # Identidades del nodo
  echo "node-ip: \"${NODE_IP}\""
  [[ -n "${NODE_EXTERNAL_IP}" ]] && echo "node-external-ip: \"${NODE_EXTERNAL_IP}\""

  # TLS SANs
  if [[ -n "${TLS_SAN:-}" ]]; then
    echo "tls-san:"
    IFS=',' read -r -a sans <<< "${TLS_SAN}"
    for s in "${sans[@]}"; do echo "  - \"${s}\""; done
  fi

  # HA con etcd embebido
  if [[ "${K3S_INIT:-false}" == "true" ]]; then
    echo "cluster-init: true"
  else
    echo "server: \"${K3S_JOIN_URL}\""
    echo "token: \"${K3S_TOKEN}\""
  fi

  # Snapshots etcd (opcional)
  [[ -n "${ETCD_SNAPSHOT_CRON:-}" ]] && echo "etcd-snapshot-schedule-cron: \"${ETCD_SNAPSHOT_CRON}\""
  [[ -n "${ETCD_SNAPSHOT_RETENTION:-}" ]] && echo "etcd-snapshot-retention: ${ETCD_SNAPSHOT_RETENTION}"
} >/etc/rancher/k3s/config.yaml
chmod 600 /etc/rancher/k3s/config.yaml

echo "==> Instalar k3s (server)"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh - || true
systemctl enable --now k3s

echo "==> iscsid (por si el master aloja réplicas/Longhorn)"
systemctl enable --now iscsid || true

if [[ "${ENABLE_DDCLIENT:-true}" == "true" ]]; then
  echo "==> Configurar ddclient (Cloudflare) en /etc/ddclient.conf"
  need CLOUDFLARE_TOKEN; need CF_ZONE; need CF_RECORDS
  : "${CF_TTL:=300}"

  cat >/etc/ddclient.conf <<EOF
syslog=yes
use=web
web=https://api.ipify.org/
web-skip=""
protocol=cloudflare \\
zone=${CF_ZONE} \\
ttl=${CF_TTL} \\
login=token \\
password=${CLOUDFLARE_TOKEN} \\
${CF_RECORDS}
ssl=yes
EOF
  chown root:root /etc/ddclient.conf
  chmod 600 /etc/ddclient.conf
  systemctl daemon-reload
  systemctl enable --now ddclient
  systemctl restart ddclient || true
fi

echo "==> Resumen:"
echo "  - k3s server: $(systemctl is-active k3s)"
echo "  - ddclient:   $(systemctl is-active ddclient 2>/dev/null || echo 'disabled')"
echo "  - resolved DNS upstreams: ${UPSTREAM_DNS}"
echo "  - NODE_EXTERNAL_IP: ${NODE_EXTERNAL_IP:-'(no detectada)'}"
echo "Listo. Verifica desde cualquier máquina con kubectl:"
echo "  kubectl get nodes -o wide"
