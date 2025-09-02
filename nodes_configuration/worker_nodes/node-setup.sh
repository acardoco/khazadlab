#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-/root/node.env}"
[[ -f "$ENV_FILE" ]] || { echo "No existe $ENV_FILE"; exit 1; }
sed -i 's/\r$//' "$ENV_FILE" 2>/dev/null || true
set -a; . "$ENV_FILE"; set +a

need() { [[ -n "${!1:-}" ]] || { echo "Falta $1 en $ENV_FILE"; exit 1; }; }

echo "==> Validaciones"
need K3S_URL; need K3S_TOKEN; need K3S_NODE_IP
need IFACE_NAME; need WIFI_SSID; need WIFI_PSK; need STATIC_IP_CIDR; need GATEWAY; need DNS

echo "==> Netplan Wi-Fi estático"
cat >/etc/netplan/01-netcfg.yaml <<EOF
network:
  version: 2
  renderer: networkd
  wifis:
    ${IFACE_NAME}:
      dhcp4: no
      addresses: [${STATIC_IP_CIDR}]
      nameservers:
        addresses: [${DNS}]
      routes:
        - to: default
          via: ${GATEWAY}
      access-points:
        "${WIFI_SSID}":
          password: "${WIFI_PSK}"
EOF

echo "==> netplan apply (si estás por SSH, podría cortarse)"
netplan apply || true

echo "==> Instala paquetes"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl open-iscsi nfs-common util-linux ufw

echo "==> (opcional) Desactiva IPv6 como hiciste"
if [[ "${DISABLE_IPV6:-true}" == "true" ]]; then
  cat >/etc/sysctl.d/98-disable-ipv6.conf <<'EOF'
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
  sysctl --system || true
fi

echo "==> UFW (mismas reglas que usaste)"
if [[ "${ENABLE_UFW:-true}" == "true" ]]; then
  ufw allow 6443/tcp || true
  ufw allow 10250/tcp || true
  ufw allow 8472/udp || true
  ufw allow 30000:32767/tcp || true
  ufw allow 30000:32767/udp || true
  ufw allow 80/tcp || true
  ufw allow 443/tcp || true
  ufw allow 9100/tcp || true
  yes | ufw enable || true
fi

echo "==> (opcional) PasswordAuthentication en servidor SSH"
if [[ "${SSH_ENABLE_PASSWORD_AUTH:-false}" == "true" ]]; then
  sed -ri 's/^\s*#?\s*PasswordAuthentication\s+.*/PasswordAuthentication yes/' /etc/ssh/sshd_config || true
  systemctl reload ssh || true
fi

echo "==> iscsid para Longhorn"
systemctl enable --now iscsid || true

echo "==> Join del agente k3s (con variables del .env)"
export K3S_URL K3S_TOKEN K3S_NODE_IP
curl -sfL https://get.k3s.io | sh -

echo "==> Listo. Comprueba en el server: kubectl get nodes -o wide"
