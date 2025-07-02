## Instalacion de Grafana + Prometheus stack

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm upgrade --install prom-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f prometheus.yaml