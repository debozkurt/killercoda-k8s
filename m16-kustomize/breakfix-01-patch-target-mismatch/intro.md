# M16 — Break/fix 01: Patch Target Mismatch

> Pre-req: the M16 baseline tour. You've seen a prod overlay render and apply cleanly; this one won't build.

The `edge-relay` prod promotion isn't taking. The deploy job that runs `kubectl apply -k overlays/prod` exits non-zero, and there's no `edge-relay` Deployment in the `edge` namespace at all — not crashing, not pending, *absent*. The rest of the fleet is healthy.

This is the first place Kustomize can fail: **build time**, before a single object is sent to the API server. `apply -k` is `kustomize build` piped into `apply` — if the build errors, nothing is applied, and the cluster shows no trace of what you intended. Your usual `kubectl describe`/`logs` loop has nothing to describe.

The tree is at `/root/edge-relay`. Your job: stop looking at the cluster, render the overlay yourself, read the build error, and fix the file it points at. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
