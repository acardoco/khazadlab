## Steps Immich installation

First, create a secret:
```bash
kubectl -n immich create secret generic restic-secret \
  --from-literal=RESTIC_PASSWORD=$RESTIC_PASSWORD
```

Create the PV and PVC (with 2TB in my case):
```bash
kubectl apply -f immich-backup-nfs-pv-pvc.yaml


Apply the cronjob at 3:30 every Sunday in my case:
```bash
kubectl apply -f immich-restic-cronjob.yaml 

Try it:
kubectl -n immich create job --from=cronjob/immich-restic-backup immich-restic-backup-now


### Postgresql stuff

We'll backup the pg-1 pod with the cronjob:

```bash
kubectl apply -f immich-pg-dump-cronjob.yaml