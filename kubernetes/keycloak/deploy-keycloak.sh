source .env
envsubst < 01-secret.yaml | kubectl apply -f -
envsubst < 02-deployment.yaml | kubectl apply -f -
envsubst <  03-service.yaml | kubectl apply -f -