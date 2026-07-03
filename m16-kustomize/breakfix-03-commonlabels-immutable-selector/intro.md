# M16 — Break/fix 03: commonLabels vs the Immutable Selector

> Pre-req: the M16 baseline tour. You've seen the prod overlay apply cleanly onto an empty namespace; here it's being promoted *over an already-running Deployment*, and the API server won't allow it.

`edge-relay` is already running in `lab` and healthy. You're promoting the same base to `prod` — the standard lab → stage → prod flow — and the promotion won't land. The deploy job that runs `kubectl apply -k overlays/prod` exits non-zero, and `edge-relay` is still sitting on its lab spec (one replica, the lab image).

This is the third place Kustomize fails: **apply time**. The overlay builds fine — the render is valid YAML — but the API server *rejects* one of the objects it produces. This is a class of bug you can't catch by looking at the manifest in isolation; it only shows up when the rendered object meets the object that's already live.

The tree is at `/root/edge-relay`. Your job: reproduce the rejection, read exactly which field the API server refuses, and trace it back to the transformer that touched it. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
