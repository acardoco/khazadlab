#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
ENV_FILE="${ENV_FILE:-.env}" 

# --- Load .env ---
if [[ -f "$ENV_FILE" ]]; then
  set -o allexport
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +o allexport
else
  echo "ERROR: No se encontró $ENV_FILE" >&2
  exit 1
fi

need() { [[ -n "${!1:-}" ]] || { echo "Falta variable: $1 en $ENV_FILE" >&2; exit 1; }; }
need IFACE_NAME
need STATIC_IP_CIDR
need DNS
need GATEWAY
need WIFI_SSID
need WIFI_PSK

echo "==> Instalando paquetes NFS y soporte Wi-Fi (wpa_supplicant)"
sudo apt update
sudo apt install -y nfs-kernel-server nfs-common wpasupplicant

# --- UFW (si existe) ---
if command -v ufw >/dev/null 2>&1; then
  echo "==> Abriendo NFSv4 (TCP/2049) en UFW para la LAN 192.168.1.0/24"
  sudo ufw allow from 192.168.1.0/24 to any port 2049 proto tcp || true
fi

echo "==> Netplan Wi-Fi estático"
# Escribir con sudo tee (la redirección con > no hereda sudo)
sudo tee /etc/netplan/01-netcfg.yaml >/dev/null <<EOF
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

echo "==> netplan generate (validación previa)"
sudo netplan generate

echo "==> netplan apply (si estás por SSH, podría cortarse)"
sudo netplan apply || true

echo "✅ Listo. NFS instalado y red Wi-Fi estática configurada."
