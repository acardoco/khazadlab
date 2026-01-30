# SSH solo desde LAN (o tu IP de admin)
ufw allow from 192.168.1.0/24 to any port 22 proto tcp

# Kubernetes API: desde LAN (workers + tu máquina)
ufw allow from 192.168.1.0/24 to any port 6443 proto tcp

# Flannel VXLAN: solo entre nodos
ufw allow from 192.168.1.0/24 to any port 8472 proto udp

# Kubelet (si lo necesitas): desde LAN y/o desde pods (para metrics-server, etc.)
ufw allow from 192.168.1.0/24 to any port 10250 proto tcp
ufw allow from 10.42.0.0/16 to any port 10250 proto tcp

# Node exporter: solo desde LAN y/o pods (Prometheus dentro del clúster)
ufw allow from 192.168.1.0/24 to any port 9100 proto tcp
ufw allow from 10.42.0.0/16 to any port 9100 proto tcp

ufw allow from 192.168.1.0/24 to any port 30000:32767 proto tcp

# SSH por Tailscale
ufw allow in on tailscale0 to any port 22 proto tcp

# (si quieres) Kubernetes API por Tailscale en el master
ufw allow in on tailscale0 to any port 6443 proto tcp



## workers

# SSH solo desde LAN
ufw allow from 192.168.1.0/24 to any port 22 proto tcp

# Kubelet: desde master y/o pods
ufw allow from 192.168.1.60 to any port 10250 proto tcp
ufw allow from 10.42.0.0/16 to any port 10250 proto tcp

# Flannel VXLAN solo LAN
ufw allow from 192.168.1.0/24 to any port 8472 proto udp

# Node exporter solo LAN/pods
ufw allow from 192.168.1.0/24 to any port 9100 proto tcp
ufw allow from 10.42.0.0/16 to any port 9100 proto tcp

# NodePort: idealmente cerrado; si lo usas, solo LAN
ufw allow from 192.168.1.0/24 to any port 30000:32767 proto tcp

# SSH por Tailscale
ufw allow in on tailscale0 to any port 22 proto tcp

#valheim hosting
# ufw allow from 192.168.1.0/24 to any port 2456:2458 proto udp



## y para /etc/default/ufw
vim /etc/default/ufw # y poner IPV6=no