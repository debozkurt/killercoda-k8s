# M22 — Break/fix 02: Multi-NIC Pod Stuck ContainerCreating

> Pre-req: the M22 baseline tour (Multus, NetworkAttachmentDefinitions, the `k8s.v1.cni.cncf.io/networks` annotation).

A `media-probe` was rolled out in the `edge` namespace to pick up the macvlan RTP network as a second NIC. It never started — it's stuck in `ContainerCreating` and never goes `Ready`. Nothing about the container image or its resources is wrong; the Pod's sandbox can't be built.

When a Pod asks Multus for an extra network, Multus has to find the matching **NetworkAttachmentDefinition** before the Pod's network namespace is complete. If it can't, sandbox setup fails and the Pod hangs at `ContainerCreating` — a very different signature from a `Running` Pod with a runtime problem. NADs are namespaced objects, and a network requested by bare name is looked up in the *Pod's own* namespace.

Your job: read the event that names what Multus couldn't find, check where the NAD actually lives, and point the Pod at it. This is the same "bare name is namespace-scoped" trap as M04's cross-namespace DNS, one layer down. The cluster takes 90–150 seconds to come up (Multus adds a little). Click **Start** when ready.
