# M18 — Break/fix 02: Kustomization Suspended

> Pre-req: completed the M18 baseline tour, or comfortable with drift correction and `flux get kustomizations`.

During last night's incident, an on-call engineer scaled `dialplan` up to 5 replicas by hand to ride out a traffic spike, and suspended the `apps` Kustomization so Flux wouldn't fight the change. The incident is resolved. But `dialplan` is still running 5 replicas — git declares 2 — and Flux hasn't pulled it back the way it did in the baseline tour.

```text
+------------------------------------------------------------+
| dialplan (app-services): running 5 replicas                |
| git (apps/dialplan.yaml) declares: 2                       |
| Flux corrected this instantly in the baseline -- now it    |
| just... doesn't. Source is healthy. What changed?          |
+------------------------------------------------------------+
```

The source is fine. `flux get all` looks healthy at a glance. Yet drift that Flux corrected in seconds during the tour now persists indefinitely. This scenario tests a quiet, common failure: a consumer that was suspended and never resumed. Reconciliation is simply off for that object, and nothing errors to tell you.

The cluster takes 2–4 minutes to come up. Click **Start** when ready.
