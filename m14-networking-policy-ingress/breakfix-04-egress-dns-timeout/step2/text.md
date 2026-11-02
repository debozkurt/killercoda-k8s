# Step 2 — Fix it and verify

The lockdown is intended. Add the missing allow beside it. Do not delete the policy.

## Allow DNS

Egress policies are additive, so a second policy adds one destination. Select the CoreDNS Pods in kube-system by namespace and label, and allow port 53 on both protocols:

```bash
cat <<'YAML' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: media
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
    - to:
        - namespaceSelector: { matchLabels: { kubernetes.io/metadata.name: kube-system } }
          podSelector:       { matchLabels: { k8s-app: kube-dns } }
      ports:
        - { protocol: UDP, port: 53 }
        - { protocol: TCP, port: 53 }
YAML
```{{exec}}

DNS uses UDP by default and falls back to TCP for large answers, so allow both. The two selectors share one list entry, so they mean AND: the Pods labeled k8s-app=kube-dns in kube-system.

## Verify

Wait five seconds first, because the plugin needs a moment to apply the policy.

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local./
```{{exec}}

nginx answers. Now confirm that the lockdown survived. Call a Service in another namespace:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://portal-ui.admin-portal.svc.cluster.local./
```{{exec}}

This call fails with `wget: download timed out`, not `bad address`. The name resolves now. The policy blocks the connection to admin-portal, as intended. Read `finish.md`, then check [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m14-networking-policy-ingress/ANSWER-KEY.md).
