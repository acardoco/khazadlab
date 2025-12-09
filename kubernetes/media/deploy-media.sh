kubectl create ns media

kubectl apply -f nfs-media-pv-and-pvc.yaml

envsubst < prowlarr/01-pvc-prowlarr.yaml | kubectl apply -f -
envsubst < jellyfin/01-pvc-jellyfin.yaml | kubectl apply -f -
envsubst < qBittorrent/01-pvc-qBittorrent.yaml | kubectl apply -f -
envsubst < radarr/01-pvc-radarr.yaml | kubectl apply -f -
envsubst < sonarr/01-pvc-sonarr.yaml | kubectl apply -f -


envsubst < jellyfin/05-deployment-jellyfin.yaml | kubectl apply -f -
envsubst < sonarr/05-deployment-sonarr.yaml | kubectl apply -f -
envsubst < radarr/05-deployment-radarr.yaml | kubectl apply -f -
envsubst < prowlarr/05-deployment-prowlarr.yaml | kubectl apply -f -
envsubst < qBittorrent/05-deployment-qBittorrent.yaml | kubectl apply -f -


envsubst < jellyfin/06-svc-jellyfin.yaml | kubectl apply -f -
envsubst < sonarr/06-svc-sonarr.yaml | kubectl apply -f -
envsubst < radarr/06-svc-radarr.yaml | kubectl apply -f -
envsubst < prowlarr/06-svc-prowlarr.yaml | kubectl apply -f -
envsubst < qBittorrent/06-svc-qBittorrent.yaml | kubectl apply -f -

envsubst < qBittorrent/09-FlareSolverr.yaml | kubectl apply -f -

envsubst < default-headers-media.yaml | kubectl apply -f -

envsubst < jellyfin/10-ingress-jellyfin.yaml | kubectl apply -f -
envsubst < sonarr/10-ingress-sonarr.yaml | kubectl apply -f -
envsubst < radarr/10-ingress-radarr.yaml | kubectl apply -f -
envsubst < prowlarr/10-ingress-prowlarr.yaml | kubectl apply -f -
envsubst < qBittorrent/10-ingress-qBittorrent.yaml | kubectl apply -f -
