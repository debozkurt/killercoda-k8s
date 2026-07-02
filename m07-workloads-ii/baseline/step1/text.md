# Step 1 — Two controllers a Deployment can't replace

Most of the fleet is Deployments. Find the two controllers that aren't.

## The StatefulSets

```bash
kubectl get statefulset -A
```{{exec}}

Four: `media-engine` (media), `reg-proxy` (signaling), `presence` (app-services), `pstn-gateway` (edge). These are the stateful tier — each member owns its data and keeps its name. Look at the Pod names they produce:

```bash
kubectl get pods -n media -l app=media-engine
```{{exec}}

`media-engine-0`, `media-engine-1` — **ordinal** names, not the random hash a Deployment gives (`session-broker-7d9f8-abc12`). The name is stable: delete `media-engine-0` and its replacement is *also* `media-engine-0`. Contrast a Deployment's Pods:

```bash
kubectl get pods -n media -l app=session-broker
```{{exec}}

Random suffix, interchangeable. That difference — a durable ordinal vs. a throwaway hash — is the whole point of a StatefulSet.

## The DaemonSet

```bash
kubectl get daemonset -A
```{{exec}}

One: `sbc-edge` in `edge`. Note it has no replica count — `DESIRED` is the number of *nodes* it should run on. On this 2-node cluster that's `2`:

```bash
kubectl get pods -n edge -l app=sbc-edge -o wide
```{{exec}}

One `sbc-edge` Pod on each node. A DaemonSet's job is coverage — one Pod per node — not a replica count. Next: how a StatefulSet Pod gets a stable identity peers can reach.
