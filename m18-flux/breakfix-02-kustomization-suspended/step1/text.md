# Step 1 — Why the drift won't revert

In the baseline, scaling `dialplan` by hand was reverted within one reconcile. Here the same drift persists. Something turned reconciliation off.

## Confirm the drift

```bash
kubectl get deploy dialplan -n app-services
```{{exec}}

`READY 5/5`. The live count is 5.

```bash
grep replicas /root/polyphone-config/apps/dialplan.yaml
```{{exec}}

Git declares `replicas: 2`. So the cluster disagrees with git by 3 replicas — drift Flux should be correcting.

## Rule out the source

Top-down: is the source healthy?

```bash
flux get sources git
```{{exec}}

`polyphone-config` is `READY True` with a stored artifact. The source is fine — it isn't a fetch problem this time. Move to the consumer.

## Read the consumer

```bash
flux get kustomizations
```{{exec}}

Look at the `SUSPENDED` column: `apps` shows `SUSPENDED True`. Its `READY` is frozen at whatever it last was — that's why a glance looks healthy. A suspended Kustomization is not reconciling: no drift correction, no new commits applied, no pruning.

Confirm on the object:

```bash
kubectl get kustomization apps -n flux-system -o jsonpath='{.spec.suspend}{"\n"}'
```{{exec}}

`true`. That's the whole bug. Nothing is broken or failing — reconciliation was deliberately paused and never resumed, so the drift just sits there. Move to step 2 to turn it back on.
