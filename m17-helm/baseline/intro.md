# M17 — Baseline Tour

Helm is the Kubernetes package manager. Instead of hand-writing one Deployment and one Service YAML per environment, you write a **chart** once — templates plus a default `values.yaml` — and Helm renders it with the values you supply into plain manifests, applies them, and records the result as a versioned **release** it can upgrade and roll back.

This scenario runs the full Polyphone fleet plus one Helm-managed workload: a `voicemail` service, installed from a local chart at `/root/voicemail` as the release `voicemail` in the `app-services` namespace.

There is nothing broken here. The point is to *see* the four moving parts before the break/fix scenarios test them:

1. **The chart and the release** — read `Chart.yaml`, `values.yaml`, and the templates on disk, then see the live release with `helm list`.
2. **The render pipeline** — render the chart client-side with `helm template`, compare it to what's actually live with `helm get manifest`.
3. **Values and overrides** — see the values a release was installed with, then change one with `helm upgrade`.
4. **Releases and history** — walk the revision history, read `helm status`, and see where Helm stores release state.

The cluster takes 60–120 seconds to come up (it also downloads the Helm binary and installs the release). Click **Start** when ready.
