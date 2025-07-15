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

## NOTA
Hay que abrir el puerto 9100
```bash
sudo ufw allow 9100/tcp
sudo ufw reload
```

Comprobar que esta UP:
```bash
ss -tlnp | grep 9100
```