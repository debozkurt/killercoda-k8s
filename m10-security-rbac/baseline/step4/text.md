# Step 4 — Namespace enforcement: PodSecurity admission

The `securityContext` fields are optional — until a namespace **enforces** a Pod Security Standard. Then admission checks every new Pod against it.

## Nothing is enforced by default

```bash
kubectl get ns -L pod-security.kubernetes.io/enforce | grep -v kube-
```{{exec}}

The `ENFORCE` column is blank for every fleet namespace. No label means the **Privileged** (unrestricted) standard — which is why the root Pod in step 3 was admitted without complaint.

## Turn on restricted, and watch admission reject a bad Pod

```bash
kubectl create ns psa-demo
kubectl label ns psa-demo pod-security.kubernetes.io/enforce=restricted
kubectl run bad --image=busybox:1.36 -n psa-demo --restart=Never -- sleep 3600
```{{exec}}

The `run` is refused *at admission*: `... violates PodSecurity "restricted:latest": ...` listing the missing fields (`allowPrivilegeEscalation != false`, `unrestricted capabilities`, `runAsNonRoot != true`, `seccompProfile`). No Pod is created — the rejection is synchronous.

## A compliant Pod passes

```bash
kubectl apply -n psa-demo -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata: { name: good }
spec:
  securityContext: { runAsNonRoot: true, runAsUser: 1000, seccompProfile: { type: RuntimeDefault } }
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
    securityContext: { allowPrivilegeEscalation: false, capabilities: { drop: ["ALL"] } }
EOF
kubectl get pod good -n psa-demo
```{{exec}}

`good` is admitted and `Running` — it sets exactly the fields `restricted` requires. That's the whole gate: a namespace label, a standard, and a Pod that either satisfies it or never gets created. Clean up:

```bash
kubectl delete ns psa-demo
```{{exec}}

You've now seen all three gates healthy. The break/fix scenarios break each one — read `LESSON.md` for the *why*, then start with `breakfix-01`.
