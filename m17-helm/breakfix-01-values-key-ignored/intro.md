# M17 — Break/fix 01: Values Key Ignored

> Pre-req: completed the M17 baseline tour, or comfortable with `helm get values`, `helm get manifest`, and `helm upgrade`.

A teammate scaled the `voicemail` release up for a load test. They edited a values file to set 3 replicas and ran the install. The change was applied cleanly — no error. But monitoring still shows one pod.

```text
+-----------------------------------------------------+
| voicemail (app-services): scale-up not taking effect|
| values file says 3 replicas -- 1 pod running        |
| helm install exited 0, release status: deployed     |
+-----------------------------------------------------+
```

Everything *looks* fine. `helm list` says `deployed`. `helm get values` shows the 3 you asked for. Yet the Deployment runs one pod. The value is present but inert.

This scenario tests the most common Helm values mistake: a value set at a key path the chart doesn't read. Helm won't warn you — it keeps the key and moves on.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
