# Step 5 — A hand edit and the next upgrade

Helm 4 applies with **server-side apply**: the API server records a **field manager** for each field, and Helm owns the fields it applied as the manager `helm`. This step changes one of those fields with `kubectl`.

## Edit the Deployment by hand

```bash
kubectl scale deployment voicemail -n app-services --replicas=4
kubectl get deployment voicemail -n app-services
```{{exec}}

The Deployment wants 4 replicas. The release record still says 2:

```bash
helm get manifest voicemail -n app-services | grep 'replicas:'
```{{exec}}

## Run the next upgrade

Any upgrade now applies the chart's `replicas: 2` again. Run one with no change:

```bash
helm upgrade voicemail /root/voicemail --namespace app-services --reuse-values
```{{exec}}

The upgrade fails. The error ends with `conflict with "kubectl" with subresource "scale" using apps/v1: .spec.replicas`. It names the other manager and the exact field.

```bash
kubectl get deployment voicemail -n app-services
helm history voicemail -n app-services
```{{exec}}

Helm changed nothing: the Deployment still wants 4. Revision 4 reads `failed`, and revision 3 stays `deployed`.

## Take the field back

The chart is the source of truth here, so tell Helm to take ownership of the field again:

```bash
helm upgrade voicemail /root/voicemail \
  --namespace app-services \
  --reuse-values \
  --force-conflicts
kubectl get deployment voicemail -n app-services
```{{exec}}

Revision 5 is `deployed`, and `READY` returns to 2/2. If the hand edit had been the right change, the fix would be `--set replicaCount=4` with the same flag, so that the values carry it.
