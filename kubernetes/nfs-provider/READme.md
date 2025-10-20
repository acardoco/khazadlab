```bash
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo update
helm install csi-nfs csi-driver-nfs/csi-driver-nfs -n kube-system
```
## sobre los params en los StorageClass

- nfsvers=4.1 → Fuerza NFS v4.1 (locking integrado, menos puertos). Si tu server soporta 4.2, podrías usar 4.2; si no, elige 4.1 antes que v3.

- rsize=1048576 → Tamaño máximo de lectura por operación (1 MiB). Suele mejorar throughput en redes rápidas.

- wsize=1048576 → Tamaño máximo de escritura por operación (1 MiB).

- hard → En caso de caída del NFS, las I/O esperan hasta que el servidor vuelva (más seguro para datos; la app puede “quedarse colgada” mientras tanto).

- timeo=600 → Timeout base de RPC en décimas de segundo ⇒ 600 = 60 s. Con hard, controla el ritmo de reintentos y los mensajes de “server not responding”.