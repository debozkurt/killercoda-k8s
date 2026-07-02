# Step 1 — The default-allow to default-deny flip

A NetworkPolicy is a namespaced whitelist for pod traffic. The one idea that prevents most policy outages: a pod is default-*allow* until a policy selects it, and default-*deny* the moment one does. The `media` namespace has two policies applied — read them and see the flip.

## See the policies shaping `media`

```bash
kubectl get networkpolicy -n media
```{{exec}}

Two: `default-deny-ingress` and `allow-broker-from-app`. Look at the first:

```bash
kubectl describe networkpolicy default-deny-ingress -n media
```{{exec}}

`PodSelector: <none> (Allowing the specific traffic to all pods in this namespace)` — an empty selector, so it selects **every** pod in `media`. Its `policyTypes` is `Ingress` with no allow rules under it. That combination means one thing: deny all ingress to every pod in `media`. This is the canonical *default-deny*.

## See the allow that opens one path back up

```bash
kubectl describe networkpolicy allow-broker-from-app -n media
```{{exec}}

This one selects only `app=session-broker` and lists one ingress rule — allowing TCP:80 from the `app-services` namespace. Policies are **additive**: with both applied, the union is "session-broker accepts port 80 from app-services; everything else in media is denied." There is no deny *rule* anywhere — isolation comes from the *absence* of an allow.

## The instinct to build

Before any policy, `media` was wide open. Applying `default-deny-ingress` flipped every pod to deny; `allow-broker-from-app` added exactly one path back. That is how NetworkPolicy is always built: deny broadly, then allow narrowly. Next, prove the cluster actually enforces it.
