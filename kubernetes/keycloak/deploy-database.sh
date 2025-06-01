source postgresql/.env
kubectl create namespace keycloak
# envsubst < postgresql/00-postgresql-pvc.yaml | kubectl apply -f -
envsubst < postgresql/01-postgresql-secret.yaml | kubectl apply -f -
envsubst <  postgresql/02-postgresql-statefulset.yaml | kubectl apply -f -
envsubst <  postgresql/03-postgresql-svc.yaml | kubectl apply -f -