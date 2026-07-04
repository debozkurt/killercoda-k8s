# M18 — Baseline Tour

Flux is a GitOps delivery controller. Git holds the desired state; Flux runs inside the cluster and continuously reconciles the cluster to match it. Instead of running `kubectl apply` or `helm upgrade` by hand, you commit to git and a controller applies it for you — on a loop, forever.

This scenario runs the full Polyphone fleet plus a working Flux pipeline:

- an in-cluster **git server** (Gitea) holding a config repo, mirrored on disk at `/root/polyphone-config`
- a **`GitRepository`** source that clones that repo every minute and produces an artifact
- a **`Kustomization`** named `apps` that builds the repo's `./apps` directory and applies a `dialplan` Deployment into `app-services`
- two **`HelmRelease`s** — `message-store` (the voicemail app's backing store) and `voicemail`, which renders a chart from the same repo and is ordered after `message-store` with `dependsOn`

Nothing is broken. The point is to see the four moving parts before the break/fix scenarios test them:

1. **Flux and its sources** — confirm the controllers are running and read the `GitRepository` and its artifact revision.
2. **The Kustomization** — see the `apps` Kustomization apply the repo and read what it manages.
3. **Drift correction** — scale a Flux-managed Deployment by hand and watch Flux put it back. This is the GitOps guarantee.
4. **HelmRelease and dependencies** — read the `voicemail` release and how `dependsOn` ordered it after the `message-store` release.

The cluster takes 2–4 minutes to come up — it installs the Flux controllers, stands up the git server, seeds the repo, and runs the first reconcile. Click **Start** when ready.
