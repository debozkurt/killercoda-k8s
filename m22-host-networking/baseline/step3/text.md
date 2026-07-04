# Step 3 — a second NIC with Multus

`media-probe` keeps its normal `eth0` on the pod network **and** gets a second interface, `net1`, on a macvlan network — a dedicated media path alongside the usual one. That's Multus: a "meta" CNI that runs the cluster's default plugin for `eth0`, then attaches extra interfaces described by a **NetworkAttachmentDefinition** (NAD).

## The NAD is the definition of the extra network

```bash
kubectl get network-attachment-definitions -n media
kubectl get network-attachment-definition rtp-macvlan -n media -o yaml | grep -A15 "config:"
```{{exec}}

`rtp-macvlan` is a macvlan over the node's `eth0`, with its own `192.168.99.0/24` host-local range. A NAD is namespaced — it lives in `media`, and that placement matters (breakfix-02).

## The Pod asks for it by annotation

```bash
kubectl get pod -n media -l app=media-probe \
  -o jsonpath='{.items[0].metadata.annotations.k8s\.v1\.cni\.cncf\.io/networks}{"\n"}'
```{{exec}}

The `k8s.v1.cni.cncf.io/networks: rtp-macvlan` annotation is the request. Because the Pod is in `media` — the NAD's namespace — the bare name resolves.

## See both interfaces

```bash
kubectl exec deploy/media-probe -n media -- ls /sys/class/net
```{{exec}}

`eth0`, `lo`, and `net1` — the second NIC is there. Multus records what it attached in a status annotation:

```bash
kubectl get pod -n media -l app=media-probe \
  -o jsonpath='{.items[0].metadata.annotations.k8s\.v1\.cni\.cncf\.io/network-status}{"\n"}'
```{{exec}}

Two entries: the default network on `eth0` and `rtp-macvlan` on `net1` with a `192.168.99.x` address. The Pod is now on two networks at once.
