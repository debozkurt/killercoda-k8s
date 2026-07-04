# M18 — Break/fix 01: Source Ref Not Found

> Pre-req: completed the M18 baseline tour, or comfortable with `flux get sources`, `flux get kustomizations`, and the source → consumer split.

A change was supposed to roll out through Flux. The pipeline is configured — a `GitRepository`, an `apps` Kustomization, a `voicemail` HelmRelease — but the workloads it should deliver aren't in the cluster. `dialplan` and `voicemail` are missing from `app-services`, and nothing is in `CrashLoopBackOff` or `Pending`. There's no failing Pod to describe, because nothing was applied.

```text
+------------------------------------------------------------+
| GitOps rollout not happening                               |
| expected in app-services: dialplan, voicemail -- neither   |
| no crashing pods -- Flux is configured but delivering...   |
| ...nothing. Where did the pipeline stall?                  |
+------------------------------------------------------------+
```

This scenario tests the first reflex of debugging Flux: when a pipeline delivers nothing, read the **source** before the consumers. A stalled source freezes everything downstream, quietly, and the consumers only report they're waiting on it.

The cluster takes 2–4 minutes to come up. Click **Start** when ready.
