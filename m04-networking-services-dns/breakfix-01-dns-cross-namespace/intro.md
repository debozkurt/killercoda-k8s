# M04 — Break/fix 01: DNS — Cross-Namespace Name

> Pre-req: the M04 baseline tour. You've seen short names resolve *inside* a namespace; this is what happens across one.

A new integration has `account-provisioner` (in `provisioning`) calling the session broker, and it's failing: the team reports the broker "doesn't resolve" from provisioning. The Pod itself is `Running` — nothing crashed. This is a **name-resolution** failure, not a workload failure, which is exactly why it doesn't show up in `kubectl get pods`.

The endpoint they configured is `http://session-broker/` — the bare Service name. That name resolves fine from inside `media`, where `session-broker` actually lives. From `provisioning` it returns NXDOMAIN, because a short name is only ever tried under the *caller's* namespace.

Your job: reproduce the failure from the right namespace, read the DNS answer instead of guessing the Service is down, and give the integration the name that actually resolves. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
