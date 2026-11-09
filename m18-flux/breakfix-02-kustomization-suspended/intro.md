# M18 — Break/fix 02: Kustomization Suspended

> Pre-req: the M18 baseline, or working knowledge of drift correction and `flux get kustomizations`.

Last night a traffic spike hit `dialplan`, and the on-call engineer scaled it to 5 replicas by hand. The incident closed hours ago. Git still declares 2, and in the baseline Flux reverted the same change within a minute. This morning `dialplan` still runs 5:

```text
+------------------------------------------------------------+
| dialplan (app-services): 5 replicas                        |
| git (apps/dialplan.yaml): replicas: 2                      |
| Flux dashboard: all objects green                          |
+------------------------------------------------------------+
```

Find why Flux leaves the drift in place, and return `dialplan` to the state in git.

Setup takes about four minutes. Click **Start** when the terminal says the cluster is ready.
