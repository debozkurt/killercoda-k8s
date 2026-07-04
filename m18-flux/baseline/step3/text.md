# Step 3 — Drift correction

Flux re-applies the desired state every interval, so the cluster cannot durably disagree with git. Any out-of-band change is reverted. This is the property that makes GitOps trustworthy — and the one that surprises operators mid-incident.

## Cause drift by hand

`dialplan` is declared at 2 replicas in git. Scale it out of band, as if you were reacting to load:

```bash
kubectl scale deployment dialplan -n app-services --replicas=5
kubectl get deploy dialplan -n app-services
```{{exec}}

`READY 5/5` (or heading there). The live cluster now disagrees with git — this is **drift**.

## Watch Flux correct it

Flux would fix this on its own within the reconcile interval (1m). Force it now so you don't wait:

```bash
flux reconcile kustomization apps --with-source
```{{exec}}

This re-fetches the source and re-applies `./apps`. Now re-read the Deployment:

```bash
kubectl get deploy dialplan -n app-services
```{{exec}}

Back to `2/2`. Flux server-side-applied the git manifest (`replicas: 2`) over your change and reverted it. The correct way to make 5 replicas permanent is to change the number in git, not with `kubectl` — the controller owns that field.

## See the reconcile in the events

```bash
flux events --for Kustomization/apps | tail -5
```{{exec}}

You'll see the reconcile that re-applied the Deployment. Every correction is recorded.

## Verify

```bash
kubectl get deploy dialplan -n app-services -o jsonpath='{.spec.replicas}{"\n"}'
```{{exec}}

`2` — the declared state won. Move on to step 4.
