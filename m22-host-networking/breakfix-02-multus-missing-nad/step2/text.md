# Step 2 — Fix it and verify

The NAD is fine; the Pod just referenced it by a bare name that only ever resolves in `edge`. Point it at `media/rtp-macvlan` — the cross-namespace form.

## Qualify the network reference

```bash
kubectl patch deployment media-probe -n edge --type=merge \
  -p '{"spec":{"template":{"metadata":{"annotations":{"k8s.v1.cni.cncf.io/networks":"media/rtp-macvlan"}}}}}'
kubectl rollout status deployment/media-probe -n edge --timeout=90s
```{{exec}}

Patching the Pod template rolls a new Pod; the stuck one is replaced. Or by hand:

```bash
kubectl edit deployment media-probe -n edge
# under spec.template.metadata.annotations, change
#   k8s.v1.cni.cncf.io/networks: rtp-macvlan
# to
#   k8s.v1.cni.cncf.io/networks: media/rtp-macvlan
```

The other valid fix is to give `edge` its own copy of the NAD (`kubectl get nad rtp-macvlan -n media -o yaml`, re-`metadata.namespace` to `edge`, re-apply). Qualifying the reference is lighter when one shared definition is what you want.

## The real-world version

The rule mirrors M04's DNS lesson one layer down: **a NetworkAttachmentDefinition is namespaced, and a bare network name is looked up in the Pod's namespace — reference a NAD elsewhere as `<namespace>/<name>`.** The bare-name habit works right up until the Pod and the NAD stop sharing a namespace, then the Pod silently won't start. And the signature is worth filing away: a `ContainerCreating` Pod with a `FailedCreatePodSandBox` event is almost always a CNI/attachment problem, not the image.

## Verify

```bash
kubectl get pods -n edge -l app=media-probe -o wide
kubectl exec deploy/media-probe -n edge -- ls /sys/class/net
```{{exec}}

The Pod is `Running`, and `ls /sys/class/net` shows `eth0`, `lo`, and `net1` — the macvlan second NIC attached. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
