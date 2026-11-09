# M18 — Break/fix 04: Path Not Found

> Pre-req: the M18 baseline, or working knowledge of `flux get` and source revisions.

A platform engineer reorganized `polyphone-config` this morning and pushed one commit. The same commit raised `dialplan` to 3 replicas for the evening peak. The push succeeded, and the cluster still runs 2:

```text
+------------------------------------------------------------+
| git main: "restructure: ... scale dialplan to 3"  pushed   |
| dialplan (app-services): 2 replicas, all Ready            |
| no Pod failing                                             |
+------------------------------------------------------------+
```

The repo is cloned at `/root/polyphone-config`. Find the stage where the commit stopped, and get it delivered.

Setup takes about four minutes. Click **Start** when the terminal says the cluster is ready.
