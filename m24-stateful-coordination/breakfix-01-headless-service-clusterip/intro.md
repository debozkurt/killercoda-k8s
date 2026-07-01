# M24 — Break/fix 01: Per-Pod DNS Gone (Headless Service Lost clusterIP: None)

> Pre-req: the M24 baseline tour. You've seen a headless Service publish a stable DNS name per member; this is what happens when the Service stops being headless.

`session-cache` in the `media` plane looks healthy at a glance — `kubectl get pods -n media -l app=session-cache` shows `session-cache-0/1/2` all `Running`, nothing crashing. But peer coordination is broken: a member that tries to reach `session-cache-0.session-cache.media.svc.cluster.local` gets nothing back. The cache can't form a cluster because no member can address another by name.

The Pods are fine. The identity is fine. What broke is **discovery** — the per-Pod DNS names that only a *headless* Service publishes. Your job: confirm the per-Pod name no longer resolves, find why on the Service, and restore it. There's a sharp edge in the fix worth meeting: one Service field is immutable. The cluster takes 2–3 minutes to come up. Click **Start** when ready.
