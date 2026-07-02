# M24 — Break/fix 02: StatefulSet Wedged Behind Ordinal 0

> Pre-req: the M24 baseline tour. You've seen `OrderedReady` bring members up one at a time; this is what happens when the first one never gets Ready.

`session-cache` in the `media` plane is declared with `replicas: 3`, but the cluster only has one Pod: `session-cache-0`, and it's stuck `0/1 Running`. There is no `session-cache-1`, no `session-cache-2` — they were never created. From the caller's side the cache is effectively down: two-thirds of the members that should exist don't.

This is the signature failure of an `OrderedReady` StatefulSet, and it trips people because the missing Pods look like a scheduling or capacity problem when they're neither. Your job: understand *why* only ordinal 0 exists, find what's keeping it from becoming Ready, and fix it so the ordered cascade completes. The cluster takes 2–3 minutes to come up. Click **Start** when ready.
