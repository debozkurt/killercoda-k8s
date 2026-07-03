# Step 2 — Fix it and verify

Give the operator's ClusterRole the write verbs on Deployments its reconcile loop needs. You don't restart the operator — the loop retries every few seconds, so it picks up the new permission on its own.

## Grant the missing verbs

Re-apply the ClusterRole with the full verb set on deployments:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: tenant-operator
  labels: { plane: platform, tier: lab }
rules:
  - apiGroups: ["polyphone.example"]
    resources: ["mediatenants"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["polyphone.example"]
    resources: ["mediatenants/status"]
    verbs: ["get", "update", "patch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF
```{{exec}}

Confirm the operator's identity can now create Deployments:

```bash
kubectl auth can-i create deployments -n media \
  --as=system:serviceaccount:platform:tenant-operator
```{{exec}}

`yes`. Grant only the verbs the loop uses (`create`/`update`/`patch`/`delete` here) — an operator's ClusterRole should be as narrow as its job, not `*` on everything.

## Verify reconciliation resumes

Within ~10 seconds the loop's next pass succeeds. Watch the tenants flip to Ready:

```bash
kubectl get mediatenants -A
kubectl get deployments -n media -l managed-by=tenant-operator
```{{exec}}

`orion` and `lyra` move to `PHASE Ready` with `READY` matching `DESIRED`, and `orion-media`/`lyra-media` now exist. Confirm the denials have stopped:

```bash
kubectl logs deployment/tenant-operator -n platform --tail=6
```{{exec}}

The `Forbidden` lines are gone, replaced by `phase=Ready`. Nothing about the operator Pod changed — the same process, unblocked by the permission it was missing. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
