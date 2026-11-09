# M17 — Break/fix 02: Bad Upgrade, Rollback

> Pre-req: the M17 baseline, or working knowledge of `helm status`, `helm history` and `helm rollback`.

A deploy job ran `helm upgrade voicemail`. The command exited 0, `helm status` says `deployed`, and the pipeline is green. Ten minutes later the rollout alert fires.

```text
+-----------------------------------------------------+
| voicemail (app-services): rollout not progressing   |
| helm upgrade exited 0, release status: deployed     |
| updated replicas below desired                      |
+-----------------------------------------------------+
```

Find what the upgrade changed and return `voicemail` to a working revision. Keep the release record and the live Deployment in agreement.

Setup takes about two minutes. It installs revision 1, then runs the upgrade. Click **Start** when the terminal says the cluster is ready.
