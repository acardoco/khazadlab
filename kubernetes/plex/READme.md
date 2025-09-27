kubectl create namespace media

kubectl label nodes andres-worker media=plex --overwrite

kubectl -n media create secret generic plex-claim --from-literal=PLEX_CLAIM=claim-XXXXXXXX

## TODO deploy