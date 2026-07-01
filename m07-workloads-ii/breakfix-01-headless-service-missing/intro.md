# M07 — Break/fix 01: Headless Service Missing

A new clustered session cache, `session-store`, was deployed to `app-services` as a 3-replica StatefulSet — the members are meant to discover and replicate to each other by their stable per-Pod names. All three Pods are `Running` and look healthy. But the application logs show the members timing out trying to reach their peers, and the cluster never forms.

Nothing crashed. The Pods have their ordinal names, their storage is bound — two of the three StatefulSet guarantees are intact. The one that isn't is the network identity: a peer lookup for `session-store-0.session-store.app-services.svc.cluster.local` comes back NXDOMAIN. Your job: find why the per-Pod DNS names don't resolve even though the Pods are up, and restore them.

This is the classic StatefulSet omission — recall that the controller does *not* create the governing Service for you. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
