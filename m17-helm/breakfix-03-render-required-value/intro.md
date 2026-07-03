# M17 — Break/fix 03: Render Required Value

> Pre-req: completed the M17 baseline tour, or comfortable with `helm install`, `helm template`, and `helm show values`.

A deploy job ran `helm install voicemail` for the `app-services` namespace and failed. The pipeline is red. Voicemail never came up.

```text
+-----------------------------------------------------+
| deploy voicemail (app-services): FAILED             |
| helm install exited non-zero                        |
| no release created, no pods scheduled               |
+-----------------------------------------------------+
```

Unlike the previous two scenarios, there's nothing half-broken to inspect — the release doesn't exist and no objects were applied. The failure happened *before* the cluster was touched, during the **render** step, when Helm turns the chart + values into manifests.

This scenario tests reading a Helm render error, reproducing it offline with `helm template` (no cluster round-trip), and supplying the value the chart requires.

The cluster takes 60–120 seconds to come up. The voicemail install is *expected* to have failed — that's the scenario. Click **Start** when ready.
