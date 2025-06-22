# Instalación de Rancher con Helm


# 1. Define tus variables
```bash
export RANCHER_DOMAIN=<tu-dominio>        # e.g. rancher.midominio.local
export RANCHER_PASSWORD=<tu-contraseña>   # bootstrap password para admin
```
# 2. Añade repo y crea namespace
```bash
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
kubectl create namespace cattle-system
```
# 3. Instala Rancher
```bash
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=$RANCHER_DOMAIN \
  --set bootstrapPassword=$RANCHER_PASSWORD \
  --set ingress.tls.source=rancher \
  --set replicas=1 \
  --set ingress.ingressClassName=traefik
```
# 4. Verificar el despliegue
```bash
kubectl -n cattle-system rollout status deploy/rancher
```
# 5. Más info
 
Para más info: [Guía oficial de instalación y actualización de Rancher](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster).
