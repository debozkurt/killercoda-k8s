# M18 — Break/fix 03: HelmRelease Dependency

> Pre-req: completed the M18 baseline tour, or comfortable with `flux get helmreleases`, `dependsOn`, and reading `Ready` conditions.

The `voicemail` HelmRelease was reworked to install only after its backing store is up. Since that change, it never installs. `dialplan` (from the `apps` Kustomization) is running fine, the `message-store` release is up, the git source is healthy, and the chart renders — but `voicemail` is stuck `not ready` and no `voicemail` Deployment ever appears in `app-services`.

```text
+------------------------------------------------------------+
| voicemail (HelmRelease): stuck, never installs             |
| source: Ready   apps: Ready   message-store: Ready         |
| dialplan: Running 2/2                                       |
| ...so why is this one release blocked?                     |
+------------------------------------------------------------+
```

Everything upstream is green, which rules out the usual suspects. This scenario tests reading a `HelmRelease` that is waiting *on purpose* — blocked by `dependsOn` — and recognizing when the thing it waits for will never arrive.

The cluster takes 2–4 minutes to come up. Click **Start** when ready.
