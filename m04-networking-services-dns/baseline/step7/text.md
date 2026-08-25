# Step 7 — The rules behind the ClusterIP

The ClusterIP answered in step 6, and no process holds it. This is what actually carries the packet.

## Check which mode kube-proxy runs

```bash
kubectl -n kube-system get cm kube-proxy \
  -o jsonpath='{.data.config\.conf}' | grep -E '^mode:'
```{{exec}}

An empty value means the default, **iptables**. (`ipvs` would send you to `ipvsadm -Ln` instead, and `nftables` to `nft list ruleset` — same job, different kernel subsystem.)

## Find the Service's rule

```bash
SVC_IP=$(kubectl get svc session-broker -n media -o jsonpath='{.spec.clusterIP}')
echo "ClusterIP: $SVC_IP"
sudo iptables-save -t nat | grep "$SVC_IP"
```{{exec}}

A line in `KUBE-SERVICES` matches that destination IP and port, then jumps to a per-Service chain called `KUBE-SVC-…`. That match *is* the ClusterIP. Nothing owns the address; a rule recognises it.

## Follow it down to the Pod

```bash
CHAIN=$(sudo iptables-save -t nat | grep "$SVC_IP" \
  | grep -oE 'KUBE-SVC-[A-Z0-9]+' | head -1)
sudo iptables-save -t nat | grep -- "-A $CHAIN"
```{{exec}}

The Service chain jumps to one `KUBE-SEP-…` chain per backend — the EndpointSlice, compiled. With more than one backend you also see a `--probability` match: that is the per-connection pick.

```bash
SEP=$(sudo iptables-save -t nat | grep -- "-A $CHAIN" \
  | grep -oE 'KUBE-SEP-[A-Z0-9]+' | tail -1)
sudo iptables-save -t nat | grep -- "-A $SEP"
```{{exec}}

The last line is a `DNAT --to-destination <PodIP>:<targetPort>` — the rewrite, in the kernel, on this node. Every node holds its own copy, which is exactly why one node can fail while the rest serve the same Service perfectly.
