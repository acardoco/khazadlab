source .env

# kubectl create namespace longhorn-system

# helm install longhorn longhorn/longhorn \
#   --namespace longhorn-system \
#   --values values-longhorn.yaml

# kubectl patch storageclass local-path \
#   -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class":"false"}}}'

# kubectl patch storageclass longhorn \
#   -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class":"true"}}}'

envsubst < 01-oauth2-secret.yaml | kubectl apply -f -
envsubst < 02-oauth2-deployment.yaml | kubectl apply -f -
envsubst < 03-oauth2-service.yaml | kubectl apply -f -
envsubst < 07-oauth2-middleware-errors.yaml | kubectl apply -f -
envsubst < 08-oauth2-middleware-redirect.yaml | kubectl apply -f -
envsubst < 09-oauth2-middleware.yaml | kubectl apply -f -
envsubst < 12-ingress-longhorn.yaml | kubectl apply -f -