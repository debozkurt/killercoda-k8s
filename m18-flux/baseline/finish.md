# Done

You toured a Flux pipeline end to end: the `GitRepository` source and its artifact, the `apps` Kustomization applying the repo, drift correction reverting a hand-scaled Deployment, and the `voicemail` HelmRelease ordered after `apps` by `dependsOn`. The repo lives on the in-cluster git server and is mirrored at `/root/polyphone-config`.

**Next:**

- For the *why* — GitOps, the reconcile loop, sources vs consumers, drift, and dependency ordering — read [LESSON.md](../LESSON.md).
- **breakfix-01: Source Ref Not Found** — the GitRepository points at a branch that doesn't exist; the cluster runs nothing new and nothing crashes. Tests reading the source's `Ready` condition first.
- **breakfix-02: Kustomization Suspended** — a hand-scaled Deployment won't revert and a change won't land, while `get` output looks healthy. Tests finding a suspended consumer and `flux resume`.
- **breakfix-03: HelmRelease Dependency** — a release is stuck `not ready` and never installs. Tests reading a `dependsOn` message and correcting the reference.

After each, check yourself against [ANSWER-KEY.md](../ANSWER-KEY.md).
