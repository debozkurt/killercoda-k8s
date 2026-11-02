# Step 5 — Two guarantees

Two facts about NetworkPolicy surprise engineers. A pod's own node is always allowed, and policies never subtract. Prove both on this cluster.

## The node is always allowed

probe-demo started after the default-deny. A readiness probe is an HTTP check that the kubelet sends from the Pod's node:

```bash
kubectl get pod probe-demo -n media
kubectl describe pod probe-demo -n media
```{{exec}}

The Pod reads 1/1 Running. The Conditions section reports Ready True. No policy allows ingress to this Pod, and the probe still passes. An ingress-isolated pod always accepts connections from its own node. A deny-all policy does not fail readiness checks.

## Egress stays open

default-deny-ingress lists only Ingress in policyTypes. Pods in media are isolated for ingress and open for egress. Call out of media:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://portal-ui.admin-portal.svc.cluster.local/
```{{exec}}

portal-ui answers. Isolation is per direction.

## A second policy adds access

Signaling is denied today. Add an allow for it. Do not touch the existing policies:

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-broker-from-signaling
  namespace: media
spec:
  podSelector: { matchLabels: { app: session-broker } }
  policyTypes: [Ingress]
  ingress:
    - from:
        - namespaceSelector: { matchLabels: { kubernetes.io/metadata.name: signaling } }
      ports:
        - { protocol: TCP, port: 80 }
YAML
```{{exec}}

Wait five seconds, then repeat the call from step 2:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n signaling -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/
```{{exec}}

The call now succeeds. The union of both policies allows both namespaces. Remove the new policy and confirm the drop returns:

```bash
kubectl delete networkpolicy allow-broker-from-signaling -n media
sleep 5
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n signaling -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/
```{{exec}}

The call hangs again. Adding an allow widened access. Removing it restored the lockdown. The default-deny never changed.
