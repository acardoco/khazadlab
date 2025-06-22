# Instalación de Rancher con Helm

```bash
# 1. Define tus variables
export RANCHER_DOMAIN=<tu-dominio>        # e.g. rancher.midominio.local
export RANCHER_PASSWORD=<tu-contraseña>   # bootstrap password para admin

# 2. Añade repo y crea namespace
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update
kubectl create namespace cattle-system

# 3. Instala Rancher
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=$RANCHER_DOMAIN \
  --set bootstrapPassword=$RANCHER_PASSWORD \
  --set ingress.tls.source=rancher \
  --set replicas=1 \
  --set ingress.ingressClassName=traefik

# 4. Verificar el despliegue
kubectl -n cattle-system rollout status deploy/rancher

# 5. Más info
 
Para más info: [Guía oficial de instalación y actualización de Rancher](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster).
