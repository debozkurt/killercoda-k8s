# Step 1 — Diagnose the missing claim

Same surface as break/fix 01 — a Pod `Pending` on storage — but `get pvc` will tell a different story. Follow the claim.

## Confirm the symptom, then read the Pod's own words

```bash
kubectl get pods -n app-services -l app=directory
```{{exec}}

`directory` is `Pending`. This time the Pod's events name the exact cause:

```bash
kubectl describe pod -n app-services -l app=directory | grep -A5 Events
```{{exec}}

The event reads `persistentvolumeclaim "directory-store" not found`. The Pod is mounting a claim called `directory-store`, and the scheduler can't find it. Confirm what the Pod is asking for:

```bash
kubectl describe pod -n app-services -l app=directory | grep -A6 Volumes
```{{exec}}

Under `Volumes:`, the `ClaimName` is `directory-store`. That's the only storage reference the Pod holds.

## Now list the claims that actually exist

```bash
kubectl get pvc -n app-services
```{{exec}}

There's **no `directory-store` at all** — the claim the Pod names doesn't exist. This is the discriminator versus break/fix 01: there, `describe pod` said the claim was *unbound* and the named claim (`cdr-data`) was in the list as `Pending`; here it says the named claim is *not found* — it was never created. The Pod is pointed at a name that doesn't match anything (a typo — `directory-store` for `directory-data`). PVCs are namespaced and matched by exact name, so a one-word difference makes the claim invisible to the Pod.

You'll also see `directory-data` itself sitting `Pending` — but that's the *healthy* `WaitForFirstConsumer` from the baseline, not a second bug: nothing is consuming `directory-data`, precisely because the Pod that should is pointed at the wrong name. Fix the name and this claim gets its consumer.

The volume is fine. The Pod just isn't asking for it. On to the fix.
