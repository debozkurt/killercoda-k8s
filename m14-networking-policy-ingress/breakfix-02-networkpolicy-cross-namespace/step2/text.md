# Step 2 — Fix it and verify

Add a namespaceSelector to the peer. Keep the podSelector in the same list entry. Two selectors in one entry mean AND: Pods labeled app=sip-app in the app-services namespace.

## Correct the peer

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-broker-from-app
  namespace: media
spec:
  podSelector: { matchLabels: { app: session-broker } }
  policyTypes: [Ingress]
  ingress:
    - from:
        - namespaceSelector: { matchLabels: { kubernetes.io/metadata.name: app-services } }
          podSelector:       { matchLabels: { app: sip-app } }
      ports:
        - { protocol: TCP, port: 80 }
YAML
```{{exec}}

Both selectors sit under one dash, so both must match. Put them under two dashes and you get an OR: any Pod in app-services, plus any sip-app Pod in media. That is a looser policy.

## Verify

Wait five seconds first, because the plugin needs a moment to apply the policy.

```bash
kubectl run sip-app --rm -i --restart=Never --labels app=sip-app \
  --image=busybox:1.36 -n app-services -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/
```{{exec}}

nginx answers. Now check the precision. A client in app-services without the label must still fail, because the AND needs both selectors:

```bash
kubectl run other --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/
```{{exec}}

That call times out, as intended. Read `finish.md`, then check [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m14-networking-policy-ingress/ANSWER-KEY.md).
