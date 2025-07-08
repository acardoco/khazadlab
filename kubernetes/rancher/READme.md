# Instalación de Rancher con Helm


# 1. Define tus variables
```bash
export RANCHER_DOMAIN=<tu-dominio>        # e.g. rancher.midominio.local
export RANCHER_PASSWORD=<tu-contraseña>   # bootstrap password para admin
```
# 2. Añade repo y crea namespace
```bash
elm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update
kubectl create namespace cattle-system
```
# 3. Instala Rancher
```bash
helm install rancher rancher-latest/rancher  \
  --namespace cattle-system   \
  --set hostname=rancher.khazadlab.es  \
  --set ingress.tls.source=letsEncrypt   \
  --set letsencrypt.email=andres.cardosoc12@gmail.com   \
  --set letsencrypt.ingress.class=traefik  \
  --set replicas=1
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

# 7. Cambio de dominio
```bash
helm upgrade rancher rancher-latest/rancher \
  --namespace cattle-system \
  --reuse-values \
  --set hostname=rancher.khazadlab.es
```
