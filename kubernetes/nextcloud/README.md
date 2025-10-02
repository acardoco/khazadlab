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

# Upgrade de version

Testearlo primero

```bash
helm repo update
helm upgrade nextcloud nextcloud/nextcloud \
  -n nextcloud \
  --version 8.0.3 \
  --reuse-values \
  --set externalDatabase.enabled=false \
  --set metrics.enabled=false \
  --set metrics.rules.enabled=false \
  --dry-run --debug
```

Y subirlo

```bash
helm upgrade nextcloud nextcloud/nextcloud \
  -n nextcloud \
  --version 8.0.3 \
  --reuse-values \
  --set externalDatabase.enabled=false \
  --set metrics.enabled=false \
  --set metrics.rules.enabled=false \
  --atomic --timeout 10m
```

## NOTA si falla el upgrade

Puede que se queje por tema redis con un mensaje parecido a este:

```bash
Configuring Redis as session handler => Searching for hook scripts (*.sh) to run, located in the folder "/docker-entrypoint-hooks.d/before-starting" ==> Skipped: the "before-starting" folder is empty (or does not exist) AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 10.42.1.123. Set the 'ServerName' directive globally to suppress this message AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 10.42.1.123. Set the 'ServerName' directive globally to suppress this message 
[Thu Oct 02 20:54:29.037280 2025[] [mpm_prefork:notice[] [pid 1:tid 1] AH00163: Apache/2.4.62 (Debian) PHP/8.3.21 configured -- resuming normal operations 
[Thu Oct 02 20:54:29.037320 2025[] [core:notice[] [pid 1:tid 1] AH00094: Command line: 'apache2 -D FOREGROUND' 10.42.1.1 - - [02/Oct/2025:20:54:40 +0000] "GET /status.php HTTP/1.1" 500 1451 "-" "kube-probe/1.32" 10.42.1.1 - - [02/Oct/2025:20:54:43 +0000] "GET /status.php HTTP/1.1" 500 1447 "-" "kube-probe/1.32" 10.42.1.1 - - 
[02/Oct/2025:20:54:50 +0000] "GET /status.php HTTP/1.1" 500 1445 "-" "kube-probe/1.32" 10.42.1.1 - - [02/Oct/2025:20:54:53 +0000] "GET /status.php HTTP/1.1" 500 1447 "-" "kube-probe/1.32" 10.42.1.1 - - [02/Oct/2025:20:55:00 +0000] "GET /status.php HTTP/1.1" 500 1445 "-" "kube-probe/1.32" 10.42.1.1 - - [02/Oct/2025:20:55:03 +0000] "GET /status.php HTTP/1.1" 500 1453 "-" "kube-probe/1.32" 
[Thu Oct 02 20:55:03.908235 2025[] [mpm_prefork:notice[] [pid 1:tid 1] AH00170: caught SIGWINCH, shutting down gracefully 10.42.1.1 - - [02/Oct/2025:20:55:03 +0000] "GET /status.php HTTP/1.1" 500 1449 "-" "kube-probe/1.32" stream closed EOF for nextcloud/nextcloud-6ccfc46f49-zk4fx (nextcloud)
```

HACER esto:

```bash
cat <<'EOF' >/tmp/nextcloud-upgrade-fix.yaml
nextcloud:
  update: 1
  configs:
    003-reverse-proxy.config.php: |-
      <?php
      if (!isset($CONFIG) || !is_array($CONFIG)) { $CONFIG = []; }
      $CONFIG = array_merge($CONFIG, [
        'overwritehost'         => 'nextcloud.khazadlab.es',
        'overwriteprotocol'     => 'https',
        'overwritewebroot'      => '/',
        'overwrite.cli.url'     => 'https://nextcloud.khazadlab.es',
        'trusted_proxies'       => ['10.42.0.0/16','10.43.0.0/16','10.43.203.42','10.42.0.1'],
        'forwarded_for_headers' => ['HTTP_X_FORWARDED_FOR','HTTP_X_REAL_IP'],
        'forwarded_host_headers'=> ['HTTP_X_FORWARDED_HOST'],
        'forwarded_proto_headers'=> ['HTTP_X_FORWARDED_PROTO'],
        'memcache.local'        => '\\OC\\Memcache\\APCu',
        'memcache.distributed'  => '\\OC\\Memcache\\Redis',
        'memcache.locking'      => '\\OC\\Memcache\\Redis',
        'upload_max_chunk_size' => 104857600
      ]);
startupProbe:
  enabled: true
  initialDelaySeconds: 60
  periodSeconds: 5
  failureThreshold: 60

metrics:
  enabled: false
  rules:
    enabled: false

externalDatabase:
  enabled: false
EOF
```

Y luego:

```bash
helm upgrade nextcloud nextcloud/nextcloud \
  -n nextcloud \
  --version 8.0.3 \
  --reuse-values \
  -f /tmp/nextcloud-upgrade-fix.yaml \
  --atomic --timeout 15m
```