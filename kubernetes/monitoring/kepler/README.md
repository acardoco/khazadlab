## Instalacion de Kepler
```bash
git clone https://github.com/sustainable-computing-io/kepler.git
cd kepler
helm install kepler kepler/manifests/helm/kepler/ \
  --namespace kepler \
  --create-namespace \
  --set namespace.create=false \
  --values values.yaml
```

## Fuentes
https://github.com/sustainable-computing-io/kepler