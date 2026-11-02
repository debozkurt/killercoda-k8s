# Step 5 — Namespace enforcement: PodSecurity admission

**PodSecurity admission** is a built-in admission controller. It checks each new Pod against the Pod Security Standard that a namespace label selects.

## Nothing is enforced yet

```bash
kubectl get ns --show-labels | grep -v kube-
```{{exec}}

No fleet namespace carries a pod-security.kubernetes.io label. With no label, a namespace takes the cluster default, which is `privileged` here. That is why the root Pod in step 4 was admitted.

## Enforce restricted and send a bare Pod

```bash
kubectl create ns psa-demo
kubectl label ns psa-demo pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/warn=restricted
kubectl run bad --image=busybox:1.36 -n psa-demo --restart=Never -- sleep 3600
```{{exec}}

The API server refuses the Pod: `pods "bad" is forbidden: violates PodSecurity "restricted:latest"`. The message lists each failed check: `allowPrivilegeEscalation != false`, `unrestricted capabilities`, `runAsNonRoot != true`, and `seccompProfile`. No Pod exists.

## Send the same thing as a Deployment

```bash
kubectl create deployment bad-deploy --image=busybox:1.36 -n psa-demo -- sleep 3600
kubectl get deploy,pods -n psa-demo
```{{exec}}

This time kubectl prints `Warning: would violate PodSecurity "restricted:latest"`, and the Deployment is created. The `warn` mode checks a Deployment's Pod template. The `enforce` mode checks only Pods. The ReplicaSet tries to create the Pod and admission rejects it. The Deployment shows 0/1 and there are no Pods. Read where the refusal went:

```bash
kubectl describe rs -n psa-demo -l app=bad-deploy | tail -3
```{{exec}}

A `FailedCreate` event on the ReplicaSet carries the same violation text.

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

`good` is admitted and reaches `Running`. busybox runs as root by default, so `runAsUser: 1000` is required. Without it, admission accepts the Pod but the kubelet refuses to start it.
