# Step 1 — Diagnose the empty EndpointSlice

The Pods are `Running` and `Ready` and the Service has a ClusterIP. That's exactly the trap: a healthy-looking Service can still route to nothing.

## Confirm the symptom from a client

```bash
kubectl run net-test --rm -i --restart=Never --image=busybox:1.36 -n call-routing -- \
  wget -qO- --timeout=3 http://route-engine/
```{{exec}}

The connection fails — refused, or it hangs to the timeout. Useful to confirm it's broken; useless for *why*. Don't restart anything yet.

## Read what's behind the Service — the whole diagnosis

```bash
kubectl get endpointslice -n call-routing \
  -l kubernetes.io/service-name=route-engine
```{{exec}}

The slice lists **no endpoint addresses**. The Service exists, has a ClusterIP, and points at zero backends — so kube-proxy has nowhere to send the traffic and rejects it. This is the discriminator: an empty EndpointSlice means the problem is *which Pods the Service selects*, not the Pods themselves.

## Find why it's empty: selector vs labels

An EndpointSlice is empty for one of two reasons — the selector matches no Pods, or the matched Pods aren't `Ready`. Check readiness first (one command rules it out):

```bash
kubectl get pods -n call-routing -l app=route-engine
```{{exec}}

They're `Running` and `1/1 READY` — so it's not readiness. That leaves the selector. Compare it to the Pods' actual labels:

```bash
kubectl describe svc route-engine -n call-routing
kubectl get pods -n call-routing --show-labels
```{{exec}}

`describe` puts both halves on one screen: the `Selector:` line is the query, and `Endpoints:` right below it is the answer — `<none>`.

The Service selects `app: route-enginev2`; the Pods are labeled `app=route-engine`. The selector matches nothing, so the EndpointSlice is empty. Someone renamed a label on one side and not the other. On to the fix.
