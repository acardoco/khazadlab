# Migracion de duckdns a CloudFlare

```bash
kubectl -n cert-manager create secret generic cloudflare-api-token-secret \
  --from-literal=api-token='TU_CLOUDFLARE_API_TOKEN'

kubectl apply -f clusterIssuer-Cloudflare.yaml
```