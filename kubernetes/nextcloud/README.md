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
  --set nextcloud-password=$NEXTCLOUD_PASWORD \
  --set redis.auth.password=$REDIS_PASSWORD \
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

*Tu servidor web todavía no está configurado correctamente para permitir la sincronización de archivos, porque la interfaz WebDAV parece estar rota. To allow this check to run you have to make sure that your Web server can connect to itself. Therefore it must be able to resolve and connect to at least one of its trusted_domains or the overwrite.cli.url. This failure may be the result of a server-side DNS mismatch or outbound firewall rule.*

Obtener IP 

```bash
kubectl -n nextcloud get svc nextcloud -o jsonpath="{.spec.clusterIP}"
# p.ej. 10.43.253.81
```

Y parchear deployment:

```bash
kubectl -n nextcloud patch deployment nextcloud --patch '{
  "spec": {
    "template": {
      "spec": {
        "hostAliases": [
          {
            "ip": "10.43.253.81",
            "hostnames": ["nextcloud.khazadlab.es"]
          }
        ]
      }
    }
  }
}'
```

*La base de datos está siendo utilizada para bloqueo de ficheros transaccional. Para mejorar el rendimiento, por favor utiliza memcache, si está disponible. Para más detalles compruebe la documentación*

Añadir redis:
```bash
redis:
  enabled: true
  auth:
    enabled: true
    password: ${REDIS_PASSWORD}
```

Inyectar configurarcion de memcache en config.php

```bash
configs:
  90-memcache.config.php: |-
    <?php
    if (!isset($CONFIG) || !is_array($CONFIG)) {
        $CONFIG = [];
    }
    $CONFIG = array_merge($CONFIG, [
      // usaremos APCu para cache local
      'memcache.local'       => '\\OC\\Memcache\\APCu',
      // Redis para cache distribuida y locking
      'memcache.distributed' => '\\OC\\Memcache\\Redis',
      'memcache.locking'     => '\\OC\\Memcache\\Redis',
      'redis' => [
        'host'     => 'nextcloud-redis',
        'port'     => 6379,
        'timeout'  => 0.0,
        'password' => '',  // si habilitaste auth, pon aquí
      ],
    ]);
```