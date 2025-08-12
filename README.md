# Khazadlab

## Introduction

Welcome to my homelab! Everything runs on **Kubernetes k3s**, with services managed by:
- **Traefik**  
- **Keycloak**  
- **Longhorn**  
- **Plex**  
- **Home Assistant**  
- and more.

### Architecture:
- The single master node is a **BMAX B3 Mini PC** (Ubuntu, Intel N5095, **8 GB** DDR4 RAM, 256 GB SSD, Intel UHD Graphics, 1000 Mbps Ethernet).
- The worker node is a **BMAX B4 Plus Mini PC** (Ubuntu, Intel N100, **16 GB** DDR4 RAM, 512 GB SSD, Intel UHD Graphics 750 MHz, 2×HDMI, 1×Type-C, supports 4K @ 60 Hz).

Also, I’ve configured my DIGI router accordingly and set up a DuckDNS DDNS to ensure consistent access.

Main url: *https://pod-test.khazadlab.es/*


### Initial setup 

First, you need to install a Linux distro (e.g., Ubuntu) on each node from a USB drive.

Then, disable CG-NAT with your ISP and request a public IP (DIGI in my case).
On your router, forward the necessary ports to the hosting node or to Traefik’s VIP (if you use MetalLB): forward 6443 and 22 to the node, 80 and 443 to Traefik’s VIP, and any others as required by the host or specific services.

After that, you can start configuring each node.

#### Setup netplan

For each node, create a Netplan config to assign an internal IP address:

```bash
root@ancaco-master-Intel:/home/ancaco# cat /etc/netplan/01-netcfg.yaml
network:
  version: 2
  # renderer: networkd
  renderer: NetworkManager 
  wifis:
    wlp2s0:
      dhcp4: no
      dhcp6: no
      addresses: [<mi-local-ip>/24]
      #nameservers:
        #addresses: [1.1.1.1, 9.9.9.9]
      routes:
        - to: default
          via: 192.168.1.1 # example
      access-points:
        "MI-SUPER-WIFI":
          password: "queMirasTonto"
```

#### Setup ddclient and connect it to your domain's provider

This is straightforward: buy a domain and obtain an API token to use on your main node.

```bash
root@ancaco-master-Intel:/home/ancaco# cat /etc/ddclient.conf
syslog=yes

# Detectar IP pública (IPv4)
use=web
web=https://api.ipify.org/  # Lee tu IP WAN real :contentReference[oaicite:3]{index=3}
web-skip=""

# Configuración de Cloudflare
protocol=cloudflare \
zone=<my-domain>   \
ttl=300              \
login=token          \
password=ahorateladigo \
<my-domain>,www.<my-domain>
ssl=yes
```

#### k3s configuration

I installed k3s with the following command:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
    --cluster-init \
    --node-ip=<asigned node IP> \
    --disable=servicelb \
    --tls-san=<my-domain>" sh - 
```