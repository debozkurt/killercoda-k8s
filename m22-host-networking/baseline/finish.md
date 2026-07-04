# Done

You toured the four ways a Pod steps off the default pod network to reach the node directly: `hostNetwork` (the Pod IP *is* the node IP, and cluster DNS survives only with `ClusterFirstWithHostNet`), `hostPort` (one container port published on the node via `portmap`, and the node-resource it consumes), a **second NIC** from a Multus NetworkAttachmentDefinition (`eth0` on the pod network plus a macvlan `net1`), and a NodePort's `externalTrafficPolicy` (`Cluster` reaches every node by forwarding; `Local` trades reach for the client's source IP). That's the shape of healthy — internalize it so each broken link stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order — each snaps one link:
  - **`breakfix-01-hostnetwork-dns`** — a hostNetwork Pod that can't resolve cluster names.
  - **`breakfix-02-multus-missing-nad`** — a multi-NIC Pod stuck `ContainerCreating`.
  - **`breakfix-03-etp-local-blackhole`** — a NodePort that works from one node and hangs from another.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
