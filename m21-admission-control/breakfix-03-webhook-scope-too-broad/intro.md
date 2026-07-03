# M21 — Break/fix 03: A Webhook Whose Scope Is Too Broad

> Pre-req: the M21 baseline tour. You saw the webhook scoped to `tenant-apps` and watched that scope hold. This is what happens when the scope is widened by accident.

A canary rollout, `sip-canary`, was deployed to the **`signaling`** namespace and never came up — `0/1`, no Pods. Read the ReplicaSet event and you get a denial you've seen before: `admission webhook "validate.admission-guard.polyphone.example" denied the request: … object is missing required label 'env'`.

Stop and notice what's strange: `admission-guard` is the **tenant** admission webhook. It governs `tenant-apps`. It has no business touching `signaling` at all — that namespace runs core fleet workloads, none of which carry an `env` label. Yet here it is, rejecting a `signaling` Pod. The workload isn't wrong; the webhook is reaching into a namespace it was never meant to govern.

This is the same `missing 'env'` denial as break/fix 02, but the fault is different: not the mutating webhook this time, but the *scope* of the validating one. The tell isn't the message — it's **where** the message is landing. Your job: read the webhook's `namespaceSelector`, see that it now matches every namespace, and narrow it back to just the one it should govern. Click **Start** when ready.
