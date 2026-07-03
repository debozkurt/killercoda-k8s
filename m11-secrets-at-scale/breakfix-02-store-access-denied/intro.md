# M11 — Break/fix 02: Store Access Denied (SecretStore Not Ready)

> Pre-req: breakfix-01. There, one reference was wrong and one sync failed. Here nothing is wrong with any reference — the operator can't reach the store at all, so *everything* it feeds is down.

Both synced consumers are broken this time: `billing-processor` in `provisioning` and `partner-connector` in `media` are each in `CreateContainerConfigError`, and neither `db-credentials` nor `partner-api` Secret exists. The operator Pod is `Running`, no crashes, no restarts.

When two unrelated workloads in two different namespaces fail the same way at the same time, that's rarely two coincidences — it's one shared dependency. Every secret in this pipeline is materialized by one operator, reading one store. If the operator can't read the store, every sync under it fails together, and the blast radius is every consumer at once.

Your job: recognize the fan-out for what it is, go to the store layer instead of chasing two Pods, prove the operator's identity lost access with the M10 reflex (`auth can-i --as=`), and restore it. The cluster takes 90–150 seconds to come up. Click **Start** when ready.
