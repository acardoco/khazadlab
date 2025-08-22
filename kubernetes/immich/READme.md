### Instalacion de IMMICH

kubectl create namespace immich

#### Creo un secret

kubectl -n immich create secret generic immich-db-auth --from-literal=password='JUEJUEJUE'

#### Desplegar el PVC

kubectl apply -f 0-pvc.yaml

