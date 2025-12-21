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