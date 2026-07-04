# M22 — Break/fix 01: hostNetwork Pod Lost Cluster DNS

> Pre-req: the M22 baseline tour, and M04's cluster-DNS scheme (`<svc>.<ns>.svc.cluster.local`, search domains).

`rtp-relay` — the hostNetwork media relay — reports that it can't reach any in-cluster Service by name. Calls to `session-broker.media` and friends fail to resolve. The Pod itself is `Running`; nothing crashed. This is a **name-resolution** failure, and it's specific to how host networking changes a Pod's DNS.

A hostNetwork Pod shares the node's network namespace, and that includes the node's view of DNS. Unless you explicitly ask for cluster DNS, the kubelet hands a hostNetwork Pod the *node's* `/etc/resolv.conf` — which knows nothing about `svc.cluster.local`. Every other Pod on the cluster resolves cluster names fine; this one can't, because of one field on its spec.

Your job: read the resolver the relay actually got, connect it to the `hostNetwork` + `dnsPolicy` combination on its spec, and give it back cluster DNS without taking it off the host network. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
