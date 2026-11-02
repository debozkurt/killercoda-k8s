# M14 — Break/fix 02: NetworkPolicy cross-namespace

> Pre-req: the M14 baseline tour and break/fix 01. You know the silent-timeout signature. This scenario adds a subtler cause.

sip-app in the app-services namespace cannot reach session-broker in media. The calls time out, as in break/fix 01. This time an allow policy exists. It is named allow-broker-from-app and it names sip-app. On paper the traffic is permitted.

It is not. The allow's peer never leaves media. A podSelector alone selects Pods in the policy's own namespace. No sip-app Pod runs in media, so the policy allows nothing.

Your job: reproduce the block as the real caller, read the allow closely enough to see why it matches nobody, and fix the peer so it crosses the namespace boundary.

The cluster takes 60–120 seconds to start. Click **Start** when ready.
