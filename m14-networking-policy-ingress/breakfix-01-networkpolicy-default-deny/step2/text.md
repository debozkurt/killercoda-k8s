# Step 2 — Fix it and verify

The default-deny is correct — a locked-down namespace is the *goal*. What's missing is the companion allow. So add one; don't delete the deny (that would throw away the isolation you want to keep).

## Add the allow

`session-broker` needs to accept traffic from its callers in the `media` namespace. Add a policy selecting it and allowing ingress from the same namespace:

```bash
cat <<'EOF' | kubectl apply -f -
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
        - podSelector: {}          # any pod in this namespace (media)
      ports:
        - { protocol: TCP, port: 80 }
EOF
```{{exec}}

`from: [{ podSelector: {} }]` means "any pod in the policy's own namespace" — the idiom for allowing intra-namespace traffic. Policies are additive, so this *adds* a permitted path on top of the deny; the deny still blocks everyone else. (If only a specific caller should reach it, narrow the `podSelector` — e.g. `matchLabels: { app: transcoder }` — instead of `{}`.)

## Verify

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://session-broker.media/
```{{exec}}

You get nginx's HTML — the intra-namespace path works again. Confirm the isolation you kept is intact: a caller from *outside* `media` is still denied.

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n signaling -- \
  wget -qO- --timeout=5 http://session-broker.media/
```{{exec}}

That one still times out — exactly right. You restored the legitimate path and left the lockdown in place. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
