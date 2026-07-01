# Step 1 — Diagnose the missing Pods

A Deployment with `0/1` ready and *no Pods at all* is not a scheduling or crash problem. It's admission.

## There's nothing to describe

```bash
kubectl get deploy,rs,pods -n payments
```{{exec}}

The Deployment is `0/1`; its ReplicaSet wants `1` but shows `0` current; and there are **no Pods** — not `Pending`, not anything. A Pod that merely failed to *schedule* would at least exist as `Pending`. Here none was created at all, which points upstream of scheduling, to admission.

## The rejection is an event on the ReplicaSet

```bash
kubectl get events -n payments | grep -i -E 'failed|forbidden'
```{{exec}}

The ReplicaSet controller keeps trying to create the Pod and keeps getting refused:

```text
FailedCreate  replicaset/payments-api-...  Error creating: pods "payments-api-..." is
forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false
(container "app" must set securityContext.allowPrivilegeEscalation=false),
unrestricted capabilities (container "app" must set securityContext.capabilities.drop=["ALL"]),
runAsNonRoot != true (pod or container must set securityContext.runAsNonRoot=true),
seccompProfile (pod or container must set securityContext.seccompProfile.type to
"RuntimeDefault" or "Localhost")
```

That message is a checklist. It names the standard (`restricted:latest`) and every field the Pod is missing.

## Confirm the namespace enforces restricted

```bash
kubectl get ns payments -o jsonpath='{.metadata.labels}'; echo
```{{exec}}

`pod-security.kubernetes.io/enforce: restricted`. The namespace was hardened; the workload was written for a permissive one. Every field in the violation is one you saw in the baseline tour — time to set them.
