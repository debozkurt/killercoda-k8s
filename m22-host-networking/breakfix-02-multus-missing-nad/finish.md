# Done

You read a `ContainerCreating` Pod as a network-attachment problem, not an image one. The `FailedCreatePodSandBox` event named the missing `rtp-macvlan` NAD; `get network-attachment-definitions -A` showed it living in `media` while the Pod asked for it by bare name from `edge`. Qualifying the reference as `media/rtp-macvlan` let Multus find it and finish the sandbox.

That instinct — **a stuck-`ContainerCreating` multi-NIC Pod → read the event, then check the NAD's namespace** — is the same namespace-scoping trap as M04's cross-namespace DNS, now for network attachments.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Multus and multi-NIC.
- Next scenario: **`breakfix-03-etp-local-blackhole`** — a Pod that's `Running` and reachable from one node but not another.
