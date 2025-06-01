## quitar el traefik que viene por defecto:
- como con k3s viene un traefik muy simplon, lo quito:
- quito el traefik con:
    
    ancaco@ancaco-master-Intel:~$ cat /etc/rancher/k3s/config.yaml
    ```bash
    disable:
        - traefik
    ```

## OPCION 1 instalar con helm
- Generar user y password para el dashboard con $ htpasswd -nbm mi-user-elegida mi-password-elegida
- Comando para instalarlo:
    ```bash
    helm upgrade --install traefik traefik/traefik \
    --namespace kube-system \
    --set hostNetwork=false \
    --set service.type=LoadBalancer \
    --set ports.web.exposedPort=80 \
    --set ports.websecure.exposedPort=443 \
    --set ports.traefik.exposedPort=8080 \
    --set ports.metrics.exposedPort=9100 \
    --set ingressRoute.dashboard.enabled=true \
    --set ingressRoute.dashboard.entryPoints={traefik} \
    --set rbac.enabled=true \
    --set extraArgs="{\
        --api.dashboard=true,\
        --entrypoints.web.address=:8000,\
        --entrypoints.websecure.address=:8443,\
        --entrypoints.traefik.address=:8080,\
        --entrypoints.traefik.auth.basic.users=\"ancaco:$(htpasswd -nbB mi-user-elegida mi-password-elegida | cut -d ':' -f2)\"\
    }"
    ```
- TODO --> prefiero hacerlo con YAMLS
