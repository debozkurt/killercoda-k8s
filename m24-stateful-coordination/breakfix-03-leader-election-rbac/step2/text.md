# Step 2 — Fix it and verify

The Role needs the leader-election verbs back on `leases`. A Role is freely mutable, so re-apply it with the full set — `get, list, watch, create, update, patch, delete`:

```bash
kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: { name: leader-election, namespace: call-routing }
rules:
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "patch"]
EOF
```{{exec}}

The RoleBinding already points the `coordinator` ServiceAccount at this Role, so the new verbs take effect immediately — no restart needed.

## Verify the permission is restored

```bash
kubectl auth can-i get    leases.coordination.k8s.io -n call-routing --as=system:serviceaccount:call-routing:coordinator
kubectl auth can-i create leases.coordination.k8s.io -n call-routing --as=system:serviceaccount:call-routing:coordinator
kubectl auth can-i update leases.coordination.k8s.io -n call-routing --as=system:serviceaccount:call-routing:coordinator
```{{exec}}

All three now return `yes`. Prove it end to end — acquire the lock *as the ServiceAccount*, exactly as the election client would:

```bash
kubectl create -f - --as=system:serviceaccount:call-routing:coordinator <<'EOF'
apiVersion: coordination.k8s.io/v1
kind: Lease
metadata: { name: call-coordinator, namespace: call-routing }
spec:
  holderIdentity: call-coordinator-leader
  leaseDurationSeconds: 15
EOF
kubectl get lease call-coordinator -n call-routing
```{{exec}}

The create succeeds — permission denied is gone — and the Lease now exists with a `HOLDER`. With the verbs restored, a replica can acquire and renew the lock, so leadership can be established and the singleton work can run. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
