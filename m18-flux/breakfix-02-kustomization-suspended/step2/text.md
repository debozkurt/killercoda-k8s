# Step 2 — Fix it and verify

The `apps` Kustomization is suspended. Resume it, and Flux reconciles again — which will correct the drift back to the git-declared 2.

## Resume reconciliation

```bash
flux resume kustomization apps
```{{exec}}

`flux resume` clears `spec.suspend` and triggers an immediate reconcile, waiting for it to finish. Watch the drift disappear:

```bash
kubectl get deploy dialplan -n app-services
```{{exec}}

Back to `2/2`. On the first reconcile after resuming, kustomize-controller re-applied `./apps` (which declares 2) over the hand-scaled 5 and adopted the Deployment. Reconciliation — and drift correction — is on again.

## Confirm it's really reconciling

```bash
flux get kustomizations
```{{exec}}

`apps` is `SUSPENDED False`, `READY True`, with a fresh `Applied revision`. Prove drift correction is live by re-drifting:

```bash
kubectl scale deployment dialplan -n app-services --replicas=4
flux reconcile kustomization apps
kubectl get deploy dialplan -n app-services
```{{exec}}

It snaps back to `2/2` — the guarantee is restored.

## The durable fix

`flux resume` is the right recovery. Two lessons outlast it. First, the emergency scale to 5 was lost because it lived only in the cluster — if 5 replicas was correct, it belonged in a git commit, not a `kubectl scale`. Second, `suspend` during an incident needs a tripwire so it isn't forgotten: an alert on suspended Flux objects, or a checklist item to `resume`. For the triage-vs-durable discussion, see [ANSWER-KEY.md](../ANSWER-KEY.md).

You're done with breakfix-02. See `finish.md`.
