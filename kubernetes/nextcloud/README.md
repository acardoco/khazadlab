## Instalar Nextcloud

```bash
kubectl create namespace nextcloud

helm repo add nextcloud https://nextcloud.github.io/helm/
helm repo update


export $(grep ^POSTGRESQL_PASSWORD .env)
helm install nextcloud nextcloud/nextcloud \
  --namespace nextcloud \
  --set postgresql.global.postgresql.auth.password=$POSTGRESQL_PASSWORD \
  --set externalDatabase.password=$POSTGRESQL_PASSWORD \
  --set nextcloud-password="$NEXTCLOUD_PASWORD" \
  -f nextcloud-values.yaml
```

# Integrar con Keycloak
Habilitar primero OIDC en el nextcloud (desde la UI se puede hacer)

```bash
kubectl -n nextcloud create secret generic nextcloud-keycloak-secret \
  --from-literal=client-secret='<SECRETITO>'
```
Toquetear añadir el OpenID Connect user backend y añadir el cliente desde la UI

```bash
helm upgrade --install nextcloud nextcloud/nextcloud \
  --namespace nextcloud \
  --set postgresql.global.postgresql.auth.password=$POSTGRESQL_PASSWORD \
  --set externalDatabase.password=$POSTGRESQL_PASSWORD \
  --set nextcloud-password="$NEXTCLOUD_PASWORD" \
  -f nextcloud-values.yaml
```

# Utilidades

Para ver el espacio disponible:
```bash
kubectl -n nextcloud exec -it deploy/nextcloud -- df -h /var/www/html/data
```

# Warnings

*One or more mimetype migrations are available. Occasionally new mimetypes are added to better handle certain file types. Migrating the mimetypes take a long time on larger instances so this is not done automatically during upgrades. Use the command `occ maintenance:repair --include-expensive` to perform the migrations.*

```bash
kubectl -n nextcloud exec -it deploy/nextcloud -- bash php occ maintenance:repair --include-expensive
```