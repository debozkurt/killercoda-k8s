# M18 — Baseline Tour

Flux is a GitOps controller. Git holds the desired state. Controllers inside the cluster fetch it and make the cluster match it, on a loop. You change the cluster by pushing a commit, not by running `kubectl apply` or `helm upgrade`.

This scenario runs the full Polyphone fleet and one working delivery pipeline:

- an in-cluster git server (Gitea) with the repo `polyphone-config`, cloned at `/root/polyphone-config`
- a **`GitRepository`** named `polyphone-config` that fetches the `main` branch every minute
- a **`Kustomization`** named `apps` that builds `./apps` and applies the `dialplan` Deployment and its ConfigMap into `app-services`
- two **`HelmRelease`s**, `message-store` and `voicemail`, that install charts from the same repo; `voicemail` waits for `message-store`

Nothing is broken. The five steps follow the pipeline:

1. **Flux and its source**: the controllers, the `GitRepository`, its revision.
2. **The Kustomization**: what `apps` built and applied, and its inventory.
3. **Drift correction**: a hand scale, and what each controller does with it.
4. **HelmRelease and dependsOn**: the releases, where Helm stores them, and the order gate.
5. **Ship a change through git**: commit, push, watch the revision move, then prune.

Setup takes about four minutes. It installs Flux, starts the git server, pushes the repo and runs the first reconcile. Click **Start** when the terminal says the cluster is ready.
