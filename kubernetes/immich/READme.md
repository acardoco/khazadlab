### Instalacion de IMMICH

Se compone de 3 componentes principales: 
1. Immich --> guarda las fotos, la propia app
2. Postgresql --> metadatos, indices, usuarios, ...
3. Redis --> temas de cache

kubectl create namespace immich

<!-- #### Creo un secret -->

<!-- kubectl -n immich create secret generic immich-db-auth --from-literal=password='JUEJUEJUE' -->

#### Instalar postgresql

Como immich no te lo instala solo (lo hace, pero esta deprecado) + necesita una cosa llamada CPNG hay que hacer varios pasos adicionales :(
https://immich.app/docs/administration/postgres-standalone/

kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.27/releases/cnpg-1.27.0.yaml

envsubst < database/01-secrets.yaml | kubectl apply -f -
kubectl apply -f database/02-cluster.yaml   

#### Desplegar el PVC

kubectl apply -f 0-pvc.yaml

#### Instalar el propio Immich

helm upgrade --install immich immich/immich \
  -n immich -f values.yaml

**NOTA
El tipo nuevo de CloudNativePG se busca en k8s con clusters.postgresql.cnpg.io

**NOTA 2

Si da errores de permisos de postgresql en el pod del server, ejecutar a mano la instalacion de extensiones en el pod del postgresql
psql -U postgres -d immich -c "CREATE EXTENSION IF NOT EXISTS ..."