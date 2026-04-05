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

## Bajar carga longhorn 1.9.2

Check rapido
```bash
kubectl -n longhorn-system get settings.longhorn.io \
  log-level \
  v2-data-engine \
  v2-data-engine-log-level \
  v2-data-engine-guaranteed-instance-manager-cpu \
  v2-data-engine-cpu-mask \
  concurrent-replica-rebuild-per-node-limit \
  replica-auto-balance \
  snapshot-data-integrity \
  v2-data-engine-snapshot-data-integrity \
  -o custom-columns=NAME:.metadata.name,VALUE:.value
NAME                                             VALUE
log-level                                        Info
v2-data-engine                                   false
v2-data-engine-log-level                         Notice
v2-data-engine-guaranteed-instance-manager-cpu   1250
v2-data-engine-cpu-mask                          0x1
concurrent-replica-rebuild-per-node-limit        2
replica-auto-balance                             disabled
snapshot-data-integrity                          fast-check
v2-data-engine-snapshot-data-integrity           fast-check
```

### Estado actual
- `log-level=Info` → OK, no está en debug. 
- `v2-data-engine=false` → OK, no está usando V2/SPDK. 
- `replica-auto-balance=disabled` → OK. 

### Cambios a hacer
1. Desactivar comprobación de integridad de snapshots:
   ```bash
   kubectl -n longhorn-system patch settings.longhorn.io snapshot-data-integrity \
     --type=merge -p '{"value":"disabled"}'
    ```
Motivo: fast-check mete carga; el default en 1.9.2 es disabled.

2. Bajar rebuilds concurrentes por nodo a 1:
```bash
kubectl -n longhorn-system patch settings.longhorn.io concurrent-replica-rebuild-per-node-limit \
  --type=merge -p '{"value":"1"}'
```
Motivo: menos picos de CPU/IO. El default es 5.

3. Para PVC nuevos, usar StorageClass con 2 réplicas:
```bash
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: longhorn-homelab
provisioner: driver.longhorn.io
allowVolumeExpansion: true
parameters:
  numberOfReplicas: "2"
  replicaAutoBalance: "disabled"
```
Motivo: menos disco, red y rebuilds que con 3 réplicas.

4. Opcional

Reducir CSI controllers a 1 réplica si quieres menos pods/overhead:
```bash
csi:
  attacherReplicaCount: 1
  provisionerReplicaCount: 1
  resizerReplicaCount: 1
  snapshotterReplicaCount: 1
```
Motivo: menos HA, menos ruido.

No tocar
```
log-level → ya está bien (Info).
v2-data-engine → ya está apagado.
v2-data-engine-guaranteed-instance-manager-cpu / v2-data-engine-cpu-mask → irrelevantes mientras V2 siga apagado.
```