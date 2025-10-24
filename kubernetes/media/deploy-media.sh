kubectl create ns media

kubectl apply -f nfs-media-pv-and-pvc.yaml

envsubst < jackett/01-pvc-jackett.yaml | kubectl apply -f -
envsubst < jellyfin/01-pvc-jellyfin.yaml | kubectl apply -f -
envsubst < qBittorrent/01-pvc-qBittorrent.yaml | kubectl apply -f -
envsubst < radarr/01-pvc-radarr.yaml | kubectl apply -f -
envsubst < sonarr/01-pvc-sonarr.yaml | kubectl apply -f -


envsubst < jellyfin/05-deployment-jellyfin.yaml | kubectl apply -f -
envsubst < sonarr/05-deployment-sonarr.yaml | kubectl apply -f -
envsubst < radarr/05-deployment-radarr.yaml | kubectl apply -f -
envsubst < jackett/05-deployment-jackett.yaml | kubectl apply -f -
envsubst < qBittorrent/05-deployment-qBittorrent.yaml | kubectl apply -f -


envsubst < jellyfin/06-svc-jellyfin.yaml | kubectl apply -f -
envsubst < sonarr/06-svc-sonarr.yaml | kubectl apply -f -
envsubst < radarr/06-svc-radarr.yaml | kubectl apply -f -
envsubst < jackett/06-svc-jackett.yaml | kubectl apply -f -
envsubst < qBittorrent/06-svc-qBittorrent.yaml | kubectl apply -f -

envsubst < default-headers-media.yaml | kubectl apply -f -
