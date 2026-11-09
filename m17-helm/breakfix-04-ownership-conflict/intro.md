# M17 — Break/fix 04: Ownership Conflict

> Pre-req: the M17 baseline and breakfix-03, or working knowledge of `helm install`, `helm template` and `kubectl describe`.

The team is moving `voicemail` from hand-applied manifests to the chart at `/root/voicemail`. The first Helm deploy job into `app-services` failed.

```text
+-----------------------------------------------------+
| deploy voicemail (app-services): FAILED             |
| helm install exited 1                               |
| no voicemail Pods in app-services                   |
+-----------------------------------------------------+
```

The job ran:

```text
helm install voicemail /root/voicemail --namespace app-services \
  --set replicaCount=2 --set config.sipRealm=polyphone.example
```

Find what blocks the install and get `voicemail` running. Other services already call `voicemail` by its Service, so keep that Service in place.

Setup takes about two minutes. Click **Start** when the terminal says the cluster is ready.
