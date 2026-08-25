# Step 6 — Inspect the Service dataplane

Step 2 reached the ClusterIP, and no process holds it. The node's Service dataplane is what recognises that address and forwards the traffic. Read the mode before you reach for a tool.

## Which dataplane is this cluster running?

```bash
kubectl -n kube-system get cm kube-proxy \
  -o jsonpath='{.data.config\.conf}' | grep -E '^mode:'
kubectl -n kube-system get pods -l k8s-app=kube-proxy -o wide
```{{exec}}

An empty `mode` means the upstream default, **iptables**. `nftables` is the newer upstream mode. Some clusters run no kube-proxy at all and use another dataplane, for example an eBPF implementation — then neither tool below applies and you inspect that implementation instead.

## Find the Service in the kernel state

For **iptables** mode:

```bash
SVC_IP=$(kubectl get svc session-broker -n media -o jsonpath='{.spec.clusterIP}')
echo "ClusterIP: $SVC_IP"
sudo iptables-save -t nat | grep "$SVC_IP"
```{{exec}}

For **nftables** mode the same lookup is:

```bash
sudo nft list ruleset 2>/dev/null | grep -A2 "$SVC_IP" || \
  echo "no nftables ruleset — this node is not in nftables mode"
```{{exec}}

A rule matches the ClusterIP and jumps to a per-Service chain. That match *is* the ClusterIP. Nothing owns the address.

## Follow it to an endpoint

```bash
CHAIN=$(sudo iptables-save -t nat | grep "$SVC_IP" \
  | grep -oE 'KUBE-SVC-[A-Z0-9]+' | head -1)
sudo iptables-save -t nat | grep -- "-A $CHAIN"
```{{exec}}

The Service chain jumps to one `KUBE-SEP-…` chain per endpoint — the EndpointSlice, compiled into kernel state. With more than one endpoint you also see a `--probability` match: the per-connection selection from step 8.

```bash
SEP=$(sudo iptables-save -t nat | grep -- "-A $CHAIN" \
  | grep -oE 'KUBE-SEP-[A-Z0-9]+' | tail -1)
sudo iptables-save -t nat | grep -- "-A $SEP"
```{{exec}}

The last line is a `DNAT --to-destination <PodIP>:<targetPort>`. Each node holds its own copy of this state, so one node can fail while the rest serve the same Service.
