# M17 — Break/fix 02: Bad Upgrade, Rollback

> Pre-req: completed the M17 baseline tour, or comfortable with `helm history`, `helm status`, and `helm rollback`.

A routine `helm upgrade` bumped the `voicemail` image tag. The command exited 0. `helm status` says `deployed`. The deploy pipeline went green.

Then the pages started: voicemail is degraded and the rollout won't finish.

```text
+-----------------------------------------------------+
| voicemail (app-services): rollout not progressing   |
| helm upgrade exited 0, release status: deployed      |
| a pod is stuck -- new revision won't become ready    |
+-----------------------------------------------------+
```

This scenario tests two things: reading past a green `helm status` to the actual workload state, and using the **revision history** to recover. A Helm release records every revision — which means a bad upgrade always has a known-good revision to return to, if you know how to find and use it.

The cluster takes 60–120 seconds to come up (it installs a healthy revision 1, then upgrades to the broken revision 2). Click **Start** when ready.
