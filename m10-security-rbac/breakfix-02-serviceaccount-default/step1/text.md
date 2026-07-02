# Step 1 — Diagnose the Forbidden

Same symptom as break/fix 01 — a reader in `CrashLoopBackOff` with a 403. This time, read *who* the 403 names.

## Confirm it's crashing

```bash
kubectl get pods -n call-routing -l app=route-watcher
```{{exec}}

`CrashLoopBackOff` again. Read the logs.

## The 403 names a different identity

```bash
kubectl logs -n call-routing deploy/route-watcher --tail=8
```{{exec}}

```text
GET /api/v1/namespaces/call-routing/endpoints -> HTTP 403
{... "message":"endpoints is forbidden: User
\"system:serviceaccount:call-routing:default\" cannot list resource
\"endpoints\" in API group \"\" in the namespace \"call-routing\"","reason":"Forbidden", ...}
```

The verb (`list`) and resource (`endpoints`) are the same as last time — but the **identity** is `...:default`, the namespace default SA. That's the tell: this workload was supposed to run as a dedicated SA, not `default`.

## The RBAC is fine — it's the Pod's identity that's wrong

Someone did create a ServiceAccount and bind it. Prove the binding is good, and that `default` is the one that's unbound:

```bash
kubectl auth can-i list endpoints -n call-routing \
  --as=system:serviceaccount:call-routing:route-watcher      # yes
kubectl auth can-i list endpoints -n call-routing \
  --as=system:serviceaccount:call-routing:default            # no
```{{exec}}

`route-watcher` is authorized; `default` is not. So the grant is correct — the Pod just isn't using it. Confirm which SA the Pod actually runs as:

```bash
kubectl get deploy route-watcher -n call-routing \
  -o jsonpath='{.spec.template.spec.serviceAccountName}'; echo
```{{exec}}

Empty — no `serviceAccountName` is set, so the Pod fell back to `default`. The permission is right; the caller isn't who you think. On to the fix.
