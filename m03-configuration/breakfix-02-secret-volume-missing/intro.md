# M03 — Break/fix 02: stuck ContainerCreating

> Pre-req: the M03 baseline tour, or comfort with mounting a Secret/ConfigMap as a volume.

The admin portal is down. `portal-ui` in the `admin-portal` namespace has been sitting in `ContainerCreating` since the last deploy and never goes `Ready`. Operators can't get in.

This is the second config-failure shape, and it looks nothing like the first. There's no `CreateContainerConfigError` and no crash — the Pod is *stuck before the container is even created*. That's the signature of a **volume** problem: the kubelet can't set up a mount the Pod requires, and mounting is a precondition to starting any container. Same family of root cause as break/fix 01 — something referenced that isn't there — but a different consumption mode, caught at a different phase, showing a different status.

Your job: recognize that `ContainerCreating` + no logs points at a mount, find the `FailedMount` event, and supply what's missing. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
