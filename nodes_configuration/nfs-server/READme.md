# README — NFS Server para Longhorn + Media en mini-PC B3 (Ubuntu)

Este documento resume **exactamente lo que se ha hecho** para preparar un **disco USB de 8 TB** (WD80EDAZ) en un mini-PC con Ubuntu, **montarlo en `/srv/nfs`**, exponerlo por **NFSv4** y **probarlo desde otros mini-PCs**, además de cómo **configurarlo en Longhorn** y qué revisar si aparece “**Backup target default is unavailable**”.

---

## 0) Datos de referencia

- **Servidor NFS (mini-PC B3)**  
  IP: `192.168.1.65`  
  Disco USB: `/dev/sda` → partición `/dev/sda1` (ext4)  
  Punto de montaje: `/srv/nfs`  
  Subcarpetas: `/srv/nfs/{media,backups,longhorn}`

- **Clientes (otros mini-PCs / nodos k3s)**  
  Montajes de prueba: `/mnt/test_nodo_master`, `/mnt/media`

- **NFSv4 con pseudo-root** (`fsid=0`): los clientes montan **`:/`** como raíz NFS y acceden a subrutas **sin** `/srv/nfs` delante (ej. `192.168.1.65:/longhorn`).

---

## 1) Comprobación del disco (SMART) en el servidor

```bash
sudo apt-get update
sudo apt-get install -y smartmontools
sudo smartctl -a -d sat /dev/sda
# (Opcional) tests:
sudo smartctl -t short -d sat /dev/sda
sudo smartctl -t long  -d sat /dev/sda
```

> Nota: el aviso “invalid SMART checksum” suele ser por el puente USB; el disco reporta **PASSED**.

---

## 2) Preparación del disco: GPT + ext4 + montaje persistente

> ⚠️ Destruye el contenido previo del disco.

```bash
# Asegura que no esté montado
sudo umount -f /dev/sda1 2>/dev/null || true

# Limpia y particiona
sudo wipefs -a /dev/sda
sudo parted -s /dev/sda mklabel gpt
sudo parted -s /dev/sda mkpart primary ext4 1MiB 100%

# Crea ext4 sin reservar 5% y con etiqueta
sudo mkfs.ext4 -L nfs_media -m 0 /dev/sda1

# Crea punto de montaje y subcarpetas
sudo mkdir -p /srv/nfs/{media,backups,longhorn}
```

### Montaje en `/etc/fstab`

```bash
UUID=$(blkid -s UUID -o value /dev/sda1)
echo "UUID=$UUID /srv/nfs ext4 defaults,noatime,lazytime,commit=120 0 2" | sudo tee -a /etc/fstab

# Aplica y verifica
sudo systemctl daemon-reload
sudo mount -a
lsblk -o NAME,FSTYPE,MOUNTPOINTS | grep sda
df -h | grep /srv/nfs
```

---

## 3) Permisos base en las carpetas exportadas

Se usa el **usuario anónimo NFS** (`nobody:nogroup`, uid/gid 65534) para simplificar permisos entre máquinas.

```bash
sudo chown -R nobody:nogroup /srv/nfs
sudo chmod 755 /srv/nfs
sudo mkdir -p /srv/nfs/media/{movies,tv}
sudo chown -R nobody:nogroup /srv/nfs/{media,backups,longhorn}
sudo chmod 2775 /srv/nfs/{media,backups,longhorn}
```

> `chmod 2775` aplica **setgid** para que nuevos ficheros hereden el grupo.

---

## 4) Servidor NFSv4

Instalación y firewall:

```bash
sudo apt-get install -y nfs-kernel-server
sudo ufw allow from 192.168.1.0/24 to any port 2049 proto tcp
```

Exportaciones (nota `fsid=0` en `/srv/nfs`):

```bash
sudo tee /etc/exports >/dev/null <<'EOF'
/srv/nfs           192.168.1.0/24(rw,sync,fsid=0,crossmnt,no_subtree_check,root_squash)
/srv/nfs/media     192.168.1.0/24(rw,sync,no_subtree_check,root_squash,all_squash,anonuid=65534,anongid=65534)
/srv/nfs/backups   192.168.1.0/24(rw,sync,no_subtree_check,root_squash,all_squash,anonuid=65534,anongid=65534)
/srv/nfs/longhorn  192.168.1.0/24(rw,sync,no_subtree_check,root_squash,all_squash,anonuid=65534,anongid=65534)
EOF

sudo exportfs -ra
sudo systemctl enable --now nfs-kernel-server
sudo exportfs -v
```

> **Importante (NFSv4 + pseudo-root):** desde clientes se monta `192.168.1.65:/` (raíz), y se accede a `/longhorn`, `/media`, etc. **sin** `/srv/nfs`.

---

## 5) Prueba desde un cliente (otro mini-PC)

Instalar cliente NFS y probar montajes:

```bash
sudo apt-get update
sudo apt-get install -y nfs-common

# Montar raíz NFSv4 para inspección
sudo mkdir -p /mnt/test_nodo_master
sudo mount -t nfs4 192.168.1.65:/ /mnt/test_nodo_master
ls -la /mnt/test_nodo_master
sudo umount /mnt/test_nodo_master

# Montar subcarpeta correcta (sin /srv/nfs):
sudo mount -t nfs4 192.168.1.65:/longhorn /mnt/test_nodo_master
touch /mnt/test_nodo_master/ok
ls -l /mnt/test_nodo_master/ok  # owner: nobody nogroup

# (Opcional) Media
sudo mkdir -p /mnt/media
sudo mount -t nfs4 192.168.1.65:/media /mnt/media
```

Montaje persistente (opcional) en `/etc/fstab` del cliente:

```
192.168.1.65:/longhorn  /mnt/test_nodo_master  nfs4  defaults,nofail,x-systemd.automount,timeo=600,retrans=3  0  0
192.168.1.65:/media     /mnt/media            nfs4  defaults,nofail,x-systemd.automount,timeo=600,retrans=3  0  0
```

Comprobaciones útiles:

```bash
# En servidor
sudo exportfs -v
cat /proc/fs/nfsd/versions

# En cliente
nfsstat -m
```

> `showmount -e` no refleja bien NFSv4. Para v4, montar `:/` y listar es lo más fiable.

---

## 6) Configuración en Longhorn

En **Longhorn UI → Settings → Backup Target**:

```
nfs://192.168.1.65:/longhorn
```

> **Ojo**: no usar `:/srv/nfs/longhorn`. Con pseudo-root (`fsid=0` en `/srv/nfs`), la ruta exportada es `:/longhorn`.

Asegúrate de que en **todos los nodos k3s** está instalado el cliente NFS:

```bash
sudo apt-get install -y nfs-common
```

---

## 7) “Backup target default is unavailable” — Checklist de diagnóstico

1. **Ruta NFS correcta**  
   Debe ser `nfs://192.168.1.65:/longhorn` (sin `/srv/nfs`).
2. **Carpeta existe y está montada en el servidor**  
   `ls -la /srv/nfs/longhorn` y `df -h | grep /srv/nfs`
3. **Permisos**  
   `/srv/nfs/longhorn` es **escribible** por `nobody:nogroup` (uid/gid 65534):  
   `ls -ld /srv/nfs/longhorn` → dueño `nobody nogroup`, modos `drwxrwsr-x` (2775).
4. **Exportaciones aplicadas**  
   `sudo exportfs -v` debe mostrar `all_squash,anonuid=65534,anongid=65534` en `longhorn`.  
   Si cambiaste `/etc/exports`: `sudo exportfs -ra && sudo systemctl restart nfs-kernel-server`.
5. **Cliente NFS en todos los nodos**  
   `nfs-common` instalado en cada nodo k3s.
6. **Firewall**  
   `ufw status` debe permitir **2049/tcp** a tu LAN (`192.168.1.0/24`).  
   Si hay VLANs/otra subred, añade reglas para esas IPs también.
7. **Protocolos NFS**  
   Longhorn usa v4.x. Si dudas, prueba manualmente desde un nodo:  
   `sudo mount -o vers=4.1 192.168.1.65:/longhorn /mnt/test && touch /mnt/test/probe && umount /mnt/test`
8. **Logs**  
   - Servidor: `sudo journalctl -u nfs-kernel-server -f`  
   - Longhorn manager:  
     ```bash
     kubectl -n longhorn-system logs deploy/longhorn-manager | grep -i -E 'nfs|backup|mount'
     ```
9. **Conectividad/estabilidad**  
   Mejor **cable** (Ethernet) que Wi-Fi en el servidor NFS. IP estática o reserva DHCP para `192.168.1.65`.

---

## 8) Notas útiles

- **NFSv4 pseudo-root**: con `fsid=0` en `/srv/nfs`, la raíz exportada es `/`.  
  Por eso se monta `192.168.1.65:/` y se accede a `/longhorn`, `/media`, etc.
- **Evitar autosuspend USB** (opcional si ves desconexiones):
  ```bash
  echo -1 | sudo tee /sys/module/usbcore/parameters/autosuspend
  echo 'options usbcore autosuspend=-1' | sudo tee /etc/modprobe.d/usb-autosuspend.conf
  ```
- **Rendimiento ext4 para HDD USB grande**: `noatime,lazytime,commit=120` reduce escrituras y mejora rendimiento en copias secuenciales (media/backups).

---

## 9) Resumen rápido (TL;DR)

1. Formatear `/dev/sda1` a **ext4** y montar en `/srv/nfs` (fstab con `UUID`, `noatime,lazytime,commit=120`).  
2. Crear `/srv/nfs/{media,backups,longhorn}` y poner **propietario `nobody:nogroup`** + `chmod 2775`.  
3. Instalar **nfs-kernel-server**, abrir **2049/tcp**, exportar con **NFSv4** (`fsid=0`) y **all_squash** a `anonuid=65534,anongid=65534`.  
4. En clientes, montar **`192.168.1.65:/longhorn`** (no `:/srv/nfs/longhorn`).  
5. En Longhorn, **Backup Target** = `nfs://192.168.1.65:/longhorn`.  
6. Si Longhorn dice “unavailable”, revisar checklist de la sección 7.
