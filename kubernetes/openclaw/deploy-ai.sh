source .env
kubectl apply -f 00-namespace.yaml
kubectl apply -f 00-quota.yaml
kubectl apply -f 00-pvc-openclaw.yaml
# kubectl apply -f 01-ollama.yaml
kubectl apply -f 02-rbac-media.yaml
kubectl apply -f 02-rbac-monitoring.yaml
envsubst < 03-openclaw-secret.yaml | kubectl apply -f -
envsubst < 04-openclaw-config.yaml | kubectl apply -f -
kubectl apply -f 05-openclaw.yaml