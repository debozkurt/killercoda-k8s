# Step 1 — Diagnose the allow that allows nothing

The timeout is the same as break/fix 01, but the cause is one layer deeper: a policy that *looks* like it permits the traffic. Reproduce it as the real caller, then read the allow closely.

## Reproduce it as sip-app, from app-services

The caller is `sip-app` in `app-services`, so test from a client with that identity — same namespace, same `app=sip-app` label:

```bash
kubectl run sip-app --rm -i --restart=Never --labels app=sip-app \
  --image=busybox:1.36 -n app-services -- \
  wget -qO- --timeout=5 http://session-broker.media/
```{{exec}}

It hangs and times out. As before, confirm the path is otherwise healthy so policy is the conclusion:

```bash
kubectl get endpoints session-broker -n media
```{{exec}}

Endpoints are present. DNS for `session-broker.media` resolves (it did in the baseline). So it's a policy — but which, and why, when one names `sip-app`?

## Read the policies — and the peer

```bash
kubectl get networkpolicy -n media
kubectl get networkpolicy allow-broker-from-app -n media -o yaml | grep -A8 ingress:
```{{exec}}

Two policies: the `default-deny-ingress`, and `allow-broker-from-app` selecting `session-broker`. The allow's `from` peer is a single `podSelector: { app: sip-app }` — and **no `namespaceSelector`**. That's the bug. A bare `podSelector` is evaluated in the *policy's own* namespace, `media`. It means "pods labeled `app=sip-app` in `media`" — and there are none. The caller lives in `app-services`, which this peer never reaches.

## Confirm the reasoning

```bash
kubectl get pods -n media -l app=sip-app
kubectl get pods -n app-services -l app=sip-app
```{{exec}}

No `sip-app` pods in `media`; the real one is in `app-services`. The allow matches an empty set, the default-deny denies everything else, and the cross-namespace call is dropped. The peer needs to name the *namespace*, not just the pod. On to the fix.
