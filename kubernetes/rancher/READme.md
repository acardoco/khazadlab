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
  --namespace cattle-system  \
  --create-namespace \
  --set hostname=$RANCHER_DOMAIN \
  --set bootstrapPassword=$RANCHER_PASSWORD \
  --set replicas=1 \
  --set ingress.tls.source=letsEncrypt  \
  --set letsencrypt.email=$EMAIL  \
  --set letsencrypt.ingress.class=traefik \
  --set ingress.ingressClassName=traefik \
  --set installCRDs=true
```
# 4. Verificar el despliegue
```bash
kubectl -n cattle-system rollout status deploy/rancher
```
# 5. Más info
 
Para más info: [Guía oficial de instalación y actualización de Rancher](https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster).

# 6. Para desinstalarlo
```bash
helm uninstall rancher -n cattle-system
kubectl get crd | grep -E 'cattle|fleet' | awk '{print $1}' | xargs kubectl delete crd
```
** NOTA **
Si se stuckea los namespace:
```bash
for ns in $(kubectl get ns --field-selector=status.phase=Terminating -o jsonpath='{.items[*].metadata.name}'); do
  echo "Forzando borrado vía raw API: $ns"
  cat <<EOF | kubectl replace --raw "/api/v1/namespaces/${ns}/finalize" -f -
{"apiVersion":"v1","kind":"Namespace","metadata":{"name":"${ns}"},"spec":{"finalizers":[]}}
EOF
done
```