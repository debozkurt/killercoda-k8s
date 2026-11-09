# M17 — Break/fix 03: Render Required Value

> Pre-req: the M17 baseline, or working knowledge of `helm install`, `helm template` and `helm show values`.

A deploy job ran `helm install voicemail` into `app-services` and failed. The pipeline is red, and voicemail never came up.

```text
+-----------------------------------------------------+
| deploy voicemail (app-services): FAILED             |
| helm install exited 1                               |
| no voicemail Pods in app-services                   |
+-----------------------------------------------------+
```

The job ran this command against the chart at `/root/voicemail`:

```text
helm install voicemail /root/voicemail --namespace app-services --set replicaCount=2
```

Find out why the install failed and get `voicemail` running with 2 replicas.

Setup takes about two minutes. Click **Start** when the terminal says the cluster is ready.
