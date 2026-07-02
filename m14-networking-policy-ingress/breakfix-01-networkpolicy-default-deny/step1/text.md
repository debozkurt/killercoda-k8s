# Step 1 — Diagnose the silent timeout

The Pods are `Running` and `Ready`, the Service has endpoints, DNS resolves. That combination with a *hanging* connection is the tell — but confirm each link before blaming policy.

## Reproduce the failure

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=5 http://session-broker.media/
```{{exec}}

It **hangs**, then `wget: download timed out`. Not `NXDOMAIN`, not `connection refused` — a silent drop. Note that: the two loud failures from M04 are already ruled out.

## Rule out the M04 layers

Walk the request path and confirm each hop is healthy, so "policy" is a conclusion, not a guess:

```bash
kubectl get endpoints session-broker -n media
kubectl run dns --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  nslookup session-broker.media
```{{exec}}

`ENDPOINTS` lists Pod IPs on `:80` (the Service has backends), and DNS resolves to the ClusterIP. Name resolves, backends exist — the request should be landing. Something is dropping it *after* all of that.

## Find the policy

A silent drop with a healthy path is a NetworkPolicy. List them in the namespace:

```bash
kubectl get networkpolicy -n media
kubectl describe networkpolicy default-deny-ingress -n media
```{{exec}}

There it is: `default-deny-ingress`, empty `podSelector` (selects every pod in `media`), `policyTypes: Ingress`, and **no ingress rules**. That means deny all ingress to every pod in the namespace — and it's the *only* policy here. In the baseline there were two; the allow that opened session-broker back up is gone. Selecting a pod flipped it to default-deny, and nothing allows the traffic back. On to the fix.
