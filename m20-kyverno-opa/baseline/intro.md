# M20 — Baseline Tour

M10 taught the three gates every API request crosses — authentication, authorization, admission. A **policy engine** lives entirely in that third gate: after RBAC has said *yes*, it inspects the object itself and decides whether this specific YAML is acceptable, rejecting it, rewriting it, or refusing its image. That is policy-as-code — your organization's rules enforced on every deploy, in every namespace, with no human in the loop.

This tour runs on the full Polyphone fleet plus one addition the setup applies for you: **Kyverno** installed as admission webhooks, three `ClusterPolicy` objects scoped to a new `tenant-apps` namespace, and one compliant workload (`tenant-web`) deployed under them. The three policies are:

- **require-resource-limits** (validate/Enforce) — every container must declare CPU and memory limits
- **add-owner-label** (mutate) — inject `owner=platform` when it's absent
- **disallow-latest-tag** (validate/Enforce) — images must carry an explicit, non-`latest` tag

Four short steps:

1. **Kyverno as admission webhooks** — the engine's Pods, the policies, and the webhook configurations it registered
2. **Validation admits the compliant, rejects the rest** — `tenant-web` was admitted; a non-compliant Pod is denied at admission
3. **Mutation injects a default** — `tenant-web`'s Pod carries an `owner` label no one wrote in the manifest
4. **Image admission gates the tag** — a `:latest` image is refused; `tenant-web`'s pinned tag passed

Nothing to fix here. See what a governed, compliant cluster looks like before the break/fix scenarios snap each control. The cluster plus Kyverno take about 2–4 minutes to come up. Click **Start** when ready.
