# M17 — Baseline Tour

Helm is the Kubernetes package manager. You write a **chart** once: templates plus a default `values.yaml`. Helm renders the chart with your values into plain manifests, applies them, and records the result as a numbered revision of a **release**.

This scenario runs the full Polyphone fleet, Helm 4, and one Helm-managed workload. The chart is at `/root/voicemail`. The release is `voicemail` in the `app-services` namespace.

Nothing is broken at the start. The five steps walk the pipeline:

1. **The chart and the release**: read the chart on disk and find the live release.
2. **Render and compare**: render the chart on your machine, then read the manifest Helm stored.
3. **Values and an upgrade**: read the values the release uses, then change one.
4. **History and rollback**: walk the revisions, roll back, and find where Helm stores them.
5. **A hand edit and the next upgrade**: scale the Deployment with `kubectl`, then see how Helm 4 answers.

Setup takes about two minutes. It downloads Helm and installs the release. Click **Start** when the terminal says the cluster is ready.
