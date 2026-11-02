# Step 1 — Diagnose the missing Pods

A scheduling failure leaves a `Pending` Pod. A crash leaves a restarting Pod. Here no Pod exists at all.

## List the chain

```bash
kubectl get deploy,rs,pods -n payments
```{{exec}}

The Deployment reads 0/1. Its ReplicaSet wants 1 and has 0 current. No Pods exist. The ReplicaSet controller tried to create a Pod, and the API server refused it before it was stored.

## Read the ReplicaSet's events

```bash
kubectl describe rs -n payments -l app=payments-api
```{{exec}}

The `Events:` section at the bottom has `FailedCreate` lines:

```text
Error creating: pods "payments-api-…" is forbidden: violates PodSecurity "restricted:latest":
allowPrivilegeEscalation != false (…), unrestricted capabilities (…),
runAsNonRoot != true (…), seccompProfile (…)
```

The message names the level, `restricted:latest`, and each check the Pod failed. The Deployment shows the same fault as a condition:

```bash
kubectl describe deploy payments-api -n payments
```{{exec}}

In the `Conditions:` table, read the row `ReplicaFailure   True    FailedCreate`.

## Read the namespace policy

```bash
kubectl describe ns payments
```{{exec}}

The `Labels:` block holds pod-security.kubernetes.io/enforce=restricted, plus the matching `warn` and `audit` labels. `enforce` rejects Pods. It does not check the Deployment, which is why the Deployment exists and its Pods do not.
