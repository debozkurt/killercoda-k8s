# M15 — Break/fix 01: Sidecar Not Injected

> Pre-req: the M15 baseline tour. You've seen meshed pods come up `2/2` and STRICT mTLS work between them. This is the same mesh with one workload left out of it.

Callers of `session-broker` in the `media` namespace are getting `503`s. The usual checks look fine: `kubectl get pods -n media` shows `session-broker` `Running` and `Ready`, `kubectl get endpoints session-broker -n media` lists its Pod IP, and DNS resolves. The application container is healthy and serving.

But this is a meshed namespace, and every caller's sidecar has been told (by the `session-broker` DestinationRule) to reach it over Istio mTLS. If `session-broker` isn't actually *in* the mesh — no sidecar to terminate that mTLS — the handshake has nothing to talk to, and the caller's Envoy returns `503`. Someone deployed `session-broker` with sidecar injection turned off for the workload, so it's running bare in a mesh that expects everyone to be enrolled.

Your job: recognize that the `503` is a mesh-membership problem, not an app problem, find the workload that isn't in the mesh, and re-enroll it — without weakening the mTLS everyone else depends on. The cluster takes 3–5 minutes to come up. Click **Start** when ready.
