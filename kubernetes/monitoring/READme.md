## Instalacion de Grafana + Prometheus stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring
```

Cambia el valor en  ```client_secret: juejuejue``` por el secret del cliente de Keycloak

```bash
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set-string grafana.adminPassword="$GRAFANA_PASSWORD" \
  -f prometheus.yaml
```