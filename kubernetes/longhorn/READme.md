# Comandos basicos de instalacion

```bash
kubectl create namespace longhorn-system
```
```bash
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --values values-longhorn.yaml
```

# Configurar Longhorn como StorageClass predeterminado (opcional)

K3s suele crear la StorageClass local-path. Para que Longhorn sea la predeterminada:

```bash
kubectl patch storageclass local-path \
  -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class":"false"}}}'

kubectl patch storageclass longhorn \
  -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
# Integracion con keycloak para acceder desde fuera

Aplicar el script deploy-longhorn.sh

# Sobre los dos ingreses:

# Upgrade:

```bash
helm upgrade longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --version 1.9.2 \
  --values values-longhorn.yaml
```