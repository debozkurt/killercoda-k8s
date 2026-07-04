# Done

You separated "the Pod is down" from "the Pod can't resolve cluster names." `rtp-relay` was `Running` the whole time; what failed was DNS, because a hostNetwork Pod inherits the node's resolver unless you set `dnsPolicy: ClusterFirstWithHostNet`. Reading `resolv.conf` inside the Pod — and comparing it to a normal Pod's — is what made the wrong resolver visible; the one field put cluster DNS back without giving up the host network.

That instinct — **on a hostNetwork Pod, check `dnsPolicy` before you suspect CoreDNS** — is the first host-networking trap most SREs meet.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § hostNetwork.
- Next scenario: **`breakfix-02-multus-missing-nad`** — a multi-NIC Pod that never even starts.
