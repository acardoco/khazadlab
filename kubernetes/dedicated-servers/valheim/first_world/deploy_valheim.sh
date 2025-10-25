kubectl create namespace valheim

source .env
envsubst < 00-pvc-valheim.yaml | kubectl apply -f -
envsubst < 05-deploy-valheim.yaml | kubectl apply -f -
# envsubst < 06-svc-valheim.yaml | kubectl apply -f -
kubectl apply -f 07-svc-metal-valheim.yaml
# envsubst < 10-udp-ingress-valheim.yaml | kubectl apply -f -