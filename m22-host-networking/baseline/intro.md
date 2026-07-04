# M22 — Baseline Tour

Most Pods never touch the node they run on. They get an IP on the pod network, reach other Pods through Services, and the node's real interfaces stay invisible. That indirection is what makes the platform portable — and it's exactly what a real-time media plane sometimes has to give up. RTP and SIP move UDP at line rate, need the node's real ports, and care about the client's source IP. Host networking is the set of deliberate escape hatches for those cases: `hostNetwork`, `hostPort`, a second NIC via Multus, and the `externalTrafficPolicy` on a NodePort.

This tour runs on the full Polyphone fleet, plus four workloads this module layers on to show each escape hatch healthy before the break/fix scenarios bend it. Multus is installed for the multi-NIC step.

Four short steps:

1. **hostNetwork — the Pod is the node** — `rtp-relay` shares the node's network namespace: its Pod IP *is* the node IP, and it keeps cluster DNS only because it asked for it
2. **hostPort — one port onto the node** — `sip-edge` maps the node's `:5060` straight to a container, keeping its normal pod IP
3. **A second NIC with Multus** — `media-probe` gets `eth0` on the pod network plus a macvlan `net1` from a NetworkAttachmentDefinition
4. **externalTrafficPolicy on a NodePort** — `rtp-ingress` is reachable from every node's IP, and why that depends on one field

Nothing to fix here. See what healthy looks like before each link breaks. The cluster takes 90–150 seconds to come up (Multus adds a little). Click **Start** when ready.
