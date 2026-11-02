# Step 2 — Fix it and verify

The default-deny is correct. A locked-down namespace is the goal. The missing piece is an allow. Add one beside the deny.

## Add the allow

Let session-broker accept connections from the Pods in its own namespace:

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-session-broker-internal
  namespace: media
spec:
  podSelector: { matchLabels: { app: session-broker } }
  policyTypes: [Ingress]
  ingress:
    - from:
        - podSelector: {}
      ports:
        - { protocol: TCP, port: 80 }
YAML
```{{exec}}

An empty podSelector inside from means "every Pod in the policy's own namespace". Policies are additive, so this adds one allowed path and the deny still blocks everyone else. To narrow the allow, replace the empty selector with a label match such as app=transcoder.

## Verify

Wait five seconds first, because the plugin needs a moment to apply the policy.

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/
```{{exec}}

nginx answers. Now confirm the isolation survived. A caller outside media must still fail:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n signaling -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/
```{{exec}}

That call times out, as intended. You restored one path and kept the lockdown. Read `finish.md`, then check [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m14-networking-policy-ingress/ANSWER-KEY.md).
