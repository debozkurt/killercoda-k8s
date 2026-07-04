# Step 1 — Diagnose the Pod that won't start

`ContainerCreating` is a sandbox-setup problem, not a runtime one. With a multi-NIC Pod, the first suspect is the network attachment — read the event, then find where the NAD actually is.

## Confirm the signature

```bash
kubectl get pods -n edge -l app=media-probe -o wide
```{{exec}}

`STATUS` is `ContainerCreating` and stays there — the container never runs, so logs would tell you nothing. The reason is in the Pod's events:

```bash
kubectl describe pod -n edge -l app=media-probe | tail -20
```{{exec}}

The `FailedCreatePodSandBox` event is from Multus, and it names what it couldn't find — a NetworkAttachmentDefinition called `rtp-macvlan`, in the `edge` namespace. That's the lead.

## Read what the Pod asked for

```bash
kubectl get pod -n edge -l app=media-probe \
  -o jsonpath='{.items[0].metadata.annotations.k8s\.v1\.cni\.cncf\.io/networks}{"\n"}'
```{{exec}}

The annotation is the bare name `rtp-macvlan`. A bare network name is resolved against the **Pod's own namespace** — so Multus looked for `rtp-macvlan` in `edge`.

## Find where the NAD really lives

```bash
kubectl get network-attachment-definitions -A
```{{exec}}

There's exactly one `rtp-macvlan` — in the `media` namespace, not `edge`. The NAD exists; the Pod is asking for it in the wrong place. NADs are namespaced, and a bare name never crosses the namespace boundary. To reach one in another namespace you qualify it as `<namespace>/<name>` — here, `media/rtp-macvlan`. On to the fix.
