# M18 — Break/fix 03: HelmRelease Dependency

> Pre-req: the M18 baseline, or working knowledge of `flux get helmreleases` and `dependsOn`.

The `voicemail` HelmRelease waits for its backing store with `dependsOn`. Last sprint the store's HelmRelease was renamed. This cluster was built from the repo this morning, and `voicemail` never installed:

```text
+------------------------------------------------------------+
| voicemail (app-services): no Deployment                    |
| source: Ready   apps: Ready   message-store: Ready         |
| chart: renders with helm template                          |
+------------------------------------------------------------+
```

Everything around the release is green. Find what holds it, and get `voicemail` installed.

Setup takes about four minutes. Click **Start** when the terminal says the cluster is ready.
