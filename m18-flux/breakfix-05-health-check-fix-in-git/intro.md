# M18 — Break/fix 05: Health Check, Fix in Git

> Pre-req: the M18 baseline, including step 5 (a commit and a push).

A release commit for `dialplan` merged ten minutes ago. Since then the GitOps alert fires:

```text
+------------------------------------------------------------+
| ALERT  Kustomization flux-system/apps  Ready=False         |
| dialplan (app-services): rollout not progressing           |
| old Pods still serving                                     |
+------------------------------------------------------------+
```

The repo is cloned at `/root/polyphone-config`. Restore `dialplan` to a healthy rollout, and make the fix stay.

Setup takes about five minutes. Click **Start** when the terminal says the cluster is ready.
