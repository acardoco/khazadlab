## Pasos instalacion de AdGuardHome: MetalLB + Load Balancer

Opto por usar metalLB y loadBalancer para evitar tocar demasiado las configuraciones a nivel de nodo.

### Instalacion MetalLB

helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm upgrade --install metallb metallb/metallb \
  -n metallb-system --create-namespace

Y meto los componentes necesarios de DNS

kubectl apply -f 00-metallb_pool.yaml 

Crear el ns de adguard

kubectl create namespace adguard

Y creo el statefulset y servicios

OJO: tuve que añadir dos nameservers, 1.1.1.1 y 9.9.9.9 para poder  bajarme imagenes, al menos de forma inicial, de adguard en el /etc/resolv.conf
Si el systemresolv los modifica --> 

Modificaciones en NetworkManager:
root@ancaco-master-Intel:/home/ancaco# nmcli con show | grep wlp2s0
netplan-wlp2s0-DIGIFIBRA-PLUS-NtfX  35403944-a135-34fa-a292-9bf6168faffc  wifi      wlp2s0
root@ancaco-master-Intel:/home/ancaco# nmcli con mod "netplan-wlp2s0-DIGIFIBRA-PLUS-NtfX" ipv4.ignore-auto-dns yes
root@ancaco-master-Intel:/home/ancaco# nmcli con mod "netplan-wlp2s0-DIGIFIBRA-PLUS-NtfX" ipv4.dns ""
root@ancaco-master-Intel:/home/ancaco# nmcli con up  "netplan-wlp2s0-DIGIFIBRA-PLUS-NtfX"
Conexión activada con éxito (ruta activa D-Bus: /org/freedesktop/NetworkManager/ActiveConnection/5)
root@ancaco-master-Intel:/home/ancaco# systemctl restart systemd-resolved
root@ancaco-master-Intel:/home/ancaco# nmcli con show | grep wlp2s0
netplan-wlp2s0-DIGIFIBRA-PLUS-NtfX  35403944-a135-34fa-a292-9bf6168faffc  wifi      wlp2s0
root@ancaco-master-Intel:/home/ancaco# resolvectl status wlp2s0 | sed -n '1,120p'
Link 3 (wlp2s0)
    Current Scopes: DNS
         Protocols: +DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
       DNS Servers: 1.1.1.1 8.8.8.8 9.9.9.9

Y cambiar el resolv
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
Y reiniciar el resolvf y aplicar el netplan (uite los nameservers para que no saliesen duplicados)
