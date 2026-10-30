# Step 1 — Two controllers a Deployment cannot replace

Most of the fleet runs as Deployments. Find the two controllers that are not Deployments.

## The StatefulSets

```bash
kubectl get statefulset -A
```{{exec}}

Four StatefulSets: `media-engine`, `reg-proxy`, `presence` and `pstn-gateway`. Read the Pod names they produce:

```bash
kubectl get pods -n media -l app=media-engine
```{{exec}}

`media-engine-0` and `media-engine-1` are **ordinal** names. The suffix is a number, not a random hash. Compare a Deployment in the same namespace:

```bash
kubectl get pods -n media -l app=session-broker
```{{exec}}

The suffix is random. A Deployment replaces a deleted Pod with a new name. A StatefulSet replaces `media-engine-0` with another `media-engine-0`.

## The DaemonSet

```bash
kubectl get daemonset -A
```{{exec}}

One DaemonSet: `sbc-edge`, in `edge`. It has no replica count. `DESIRED` is the number of nodes it should run on. Check where its Pods landed:

```bash
kubectl get pods -n edge -l app=sbc-edge -o wide
```{{exec}}

Read the `NODE` column. One Pod runs on each node. Next: how a StatefulSet Pod gets a name that peers can reach.
