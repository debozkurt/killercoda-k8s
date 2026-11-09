# M17 — Break/fix 01: Values Key Ignored

> Pre-req: the M17 baseline, or working knowledge of `helm get values`, `helm get manifest` and `helm upgrade`.

A teammate prepared `voicemail` for a load test. They wrote a values file that asks for 3 replicas and installed the release with it. The install exited 0.

```text
+------------------------------------------------------+
| voicemail (app-services): load test underprovisioned |
| values file asks for 3 replicas -- 1 Pod runs        |
| helm install exited 0, release status: deployed      |
+------------------------------------------------------+
```

The values file is `/root/voicemail-values.yaml` and the chart is `/root/voicemail`. Find out why the release runs 1 Pod, then make the file produce 3.

Setup takes about two minutes. Click **Start** when the terminal says the cluster is ready.
