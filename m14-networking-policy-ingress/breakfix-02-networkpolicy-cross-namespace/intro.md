# M14 — Break/fix 02: NetworkPolicy Cross-Namespace

> Pre-req: the M14 baseline tour and break/fix 01. You know the silent-timeout signature; this one adds a subtler cause.

`sip-app` in the `app-services` namespace can't reach `session-broker` in `media`. The calls time out — the same hang as break/fix 01. But this time the obvious fix is already in place: there *is* an allow policy, `allow-broker-from-app`, and it even names `sip-app`. On paper the traffic should be permitted.

It isn't, and the reason is one of the most common NetworkPolicy mistakes: the allow's peer is written in a way that never leaves `media`. A `podSelector` on its own is namespace-local — it selects pods in the *policy's* namespace, not the caller's. So a policy that looks like it allows `sip-app` allows nothing, because there's no `sip-app` pod in `media`.

Your job: reproduce the block from `app-services`, read the allow closely enough to see why it matches nobody, and fix the peer so it reaches across the namespace boundary. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
