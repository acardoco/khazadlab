kubectl create ns media

kubectl apply -f nfs-media-pv-and-pvc.yaml

envsubst < jackett/01-pvc-jackett.yaml | kubectl apply -f -
envsubst < jellyfin/01-pvc-jellyfin.yaml | kubectl apply -f -
envsubst < qBittorrent/01-pvc-qBittorrent.yaml | kubectl apply -f -
envsubst < radarr/01-pvc-radarr.yaml | kubectl apply -f -
envsubst < sonarr/01-pvc-sonarr.yaml | kubectl apply -f -


envsubst < jellyfin/05-deployment-jellyfin.yaml | kubectl apply -f -
envsubst < sonarr/05-deployment-sonarr.yaml | kubectl apply -f -
