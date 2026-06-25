# M03 — Break/fix 01: CreateContainerConfigError

> Pre-req: the M03 baseline tour, or comfort with `env`/`envFrom` and ConfigMaps.

A change went out to `session-broker` in the `media` namespace, and the new Pod won't start. Session allocation is degraded. The on-call reaches for `kubectl logs` and gets nothing — the container never started, so there's nothing to log.

This is the first of the four config-failure shapes, and the status is the tell. It's not `CrashLoopBackOff` (the process never ran) and not `ImagePullBackOff` (the image is fine). It's **`CreateContainerConfigError`** — the kubelet scheduled the Pod, went to build the container, and couldn't assemble its environment. Something the Pod references in its config doesn't exist.

Your job: read the status, let the event name the exact missing piece, and fix the reference. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
