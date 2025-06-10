<!-- README.md -->
# Despliegue de servidor dedicado de Valheim en k3s con Traefik

Este repositorio contiene los manifiestos y un script para desplegar un servidor dedicado de Valheim en un clúster k3s usando Traefik (con dashboard), DuckDNS y un router DIGI.

## Requisitos

- Clúster k3s con Traefik configurado (entryPoints UDP y dashboard en 8080).  
- DNS dinámico en DuckDNS (`DUCKDNS_SUBDOMAIN` y `DUCKDNS_TOKEN` en `.env`).  
- Acceso admin al router DIGI para redirigir puertos UDP.  
- Cliente `kubectl` apuntando al clúster.  
- (Opcional) GSLT de Steam para aparecer en la lista pública (`GSLT` en `.env`).

## Archivos YAML

1. **00-pvc-valheim.yaml** – PVC de 5 Gi para datos de Valheim  
2. **05-deploy-valheim.yaml** – Deployment del servidor  
3. **06-svc-valheim.yaml** – Service ClusterIP UDP  
4. **10-udp-ingress-valheim.yaml** – IngressRouteUDP para Traefik  

## Traefik
Crear el archivo que viene en ```kubernetes/dedicated-servers/valheim/helm_stuff/traefik-config-aditionals.yaml``` y reiniciar k3s (las explicaciones vienen el el propio yaml)

## Desplegar el servidor
Ejecutar el script ``` deploy_valheim.sh ```