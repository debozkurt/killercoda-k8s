# M07 — Break/fix 01: Headless Service Missing

A team deployed a clustered session cache, `session-store`, to `app-services`. It is a StatefulSet with 3 replicas. The members must find each other by their per-Pod DNS names, and replicate to each other.

All three Pods are `Running` and look healthy. The application logs show the members timing out as they try to reach their peers, and the cluster never forms. A lookup for `session-store-0.session-store.app-services.svc.cluster.local` returns `NXDOMAIN`.

Nothing crashed. Your job: find out why the per-Pod names do not resolve while the Pods are up, and restore them.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
