# M18 — Break/fix 01: Source Ref Not Found

> Pre-req: the M18 baseline, or working knowledge of `flux get` and the source and consumer split.

A new cluster joined the fleet this morning, and its Flux objects were applied from the platform runbook. The delivery pipeline should install `dialplan`, `message-store` and `voicemail` into `app-services`. An hour later, none of them is there:

```text
+------------------------------------------------------------+
| app-services: dialplan, message-store, voicemail MISSING   |
| no Pod in CrashLoopBackOff, no Pod Pending                 |
| Flux objects: present                                      |
+------------------------------------------------------------+
```

There is no failing Pod to describe. Find the stage of the delivery loop that stopped, and get the workloads delivered.

Setup takes about four minutes. Click **Start** when the terminal says the cluster is ready.
