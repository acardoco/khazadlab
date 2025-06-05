kubectl apply -f 00_config.yaml
kubectl apply -f 02_deployment.yaml
kubectl apply -f 04_service.yaml

# parte web
kubectl apply -f 01_config_web.yaml
kubectl apply -f 03_deployment_web.yaml
kubectl apply -f 05_service_web.yaml

kubectl apply -f 10_ingress.yaml