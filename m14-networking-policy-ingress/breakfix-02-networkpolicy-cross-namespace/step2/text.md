# Step 2 — Fix it and verify

The allow needs a `namespaceSelector` so its peer reaches into `app-services`. Combine it with the existing `podSelector` in one `from` element — that's an **AND**, and it means exactly "`sip-app` pods in `app-services`."

## Correct the peer

Re-apply the policy with both selectors in a single peer element:

```bash
cat <<'EOF' | kubectl apply -f -
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
EOF
```{{exec}}

The two selectors sit under one `-` (one list element), so both must match: a pod that is `app=sip-app` **and** in the `app-services` namespace. Watch the YAML shape — split them into two `-` elements and you'd get an OR (any pod in `app-services`, plus any `sip-app` pod in `media`), which is a different, looser policy.

## Verify

```bash
kubectl run sip-app --rm -i --restart=Never --labels app=sip-app \
  --image=busybox:1.36 -n app-services -- \
  wget -qO- --timeout=5 http://session-broker.media/
```{{exec}}

nginx's HTML comes back — the cross-namespace path is open. Check the precision you just wrote: a client in `app-services` *without* the `sip-app` label is still denied, because the AND requires both.

```bash
kubectl run other --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \
  wget -qO- --timeout=5 http://session-broker.media/
```{{exec}}

That one times out — the allow is scoped to `sip-app` only, exactly as intended. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
