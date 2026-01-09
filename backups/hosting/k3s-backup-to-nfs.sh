#!/usr/bin/env bash
set -euo pipefail

TS="$(date +%F_%H%M)"
HOST="$(hostname -s)"

# === TODO ===
NFS_SSH_HOST="root@192.168.1.65"                 
NFS_DEST_DIR="/srv/nfs/backups/k3s/${HOST}"    
RETENTION_DAYS=60                               

# tmp folder
LOCAL_DIR="/var/backups/k3s"
mkdir -p "$LOCAL_DIR"

# Detect etcd vs sqlite
if [ -d /var/lib/rancher/k3s/server/db/etcd ]; then
  TYPE="etcd"
  OUT="${LOCAL_DIR}/k3s-etcd-${TS}.zip"

  echo "[k3s] Detected embedded etcd. Creating snapshot: $OUT"
  sudo k3s etcd-snapshot save --name "k3s-etcd-${TS}" --output "$OUT"

else
  TYPE="sqlite"
  OUT="${LOCAL_DIR}/k3s-sqlite-${TS}.tgz"

  echo "[k3s] Detected sqlite. Stopping k3s briefly to copy DB/TLS/config."
  sudo systemctl stop k3s

  sudo tar -czf "$OUT" \
    /var/lib/rancher/k3s/server/db \
    /var/lib/rancher/k3s/server/tls \
    /etc/rancher/k3s

  sudo systemctl start k3s
fi

echo "[copy] Sending $OUT to ${NFS_SSH_HOST}:${NFS_DEST_DIR}/"
ssh -o StrictHostKeyChecking=accept-new "$NFS_SSH_HOST" "mkdir -p '$NFS_DEST_DIR'"
rsync -ah --progress "$OUT" "${NFS_SSH_HOST}:${NFS_DEST_DIR}/"

echo "[retention] Deleting backups older than ${RETENTION_DAYS} days in NFS dest"
ssh "$NFS_SSH_HOST" "find '$NFS_DEST_DIR' -type f -mtime +${RETENTION_DAYS} -delete"

echo "[done] Backup type=${TYPE} file=$(basename "$OUT")"


sudo chmod +x /usr/local/sbin/k3s-backup-to-nfs.sh
