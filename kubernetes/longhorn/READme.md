# Configurar Longhorn como StorageClass predeterminado (opcional)

K3s suele crear la StorageClass local-path. Para que Longhorn sea la predeterminada:

```bash
kubectl patch storageclass local-path \
  -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class":"false"}}}'

kubectl patch storageclass longhorn \
  -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class":"true"}}}'
```