# Done

You toured a Helm release end to end: read the chart, watched values render into manifests, changed a value with `helm upgrade`, walked the revision history, and rolled back. The `voicemail` chart at `/root/voicemail` is the same one every M17 break/fix uses.

**Next:**

- For the *why* — the render pipeline, values precedence, the release model, and when to reach for Helm vs Kustomize — read [LESSON.md](../LESSON.md).
- **breakfix-01: Values Key Ignored** — someone set `replicas: 3` in a values file but the release still runs one pod. The value is "there" but nothing happens. Tests reading `helm get values` against the live manifest.
- **breakfix-02: Bad Upgrade, Rollback** — an upgrade reports success but the new pods won't start. Tests the revision history and `helm rollback`.
- **breakfix-03: Render Required Value** — an install fails and nothing deploys. Tests reading a render error and reproducing it with `helm template`.

After each, check yourself against [ANSWER-KEY.md](../ANSWER-KEY.md).
