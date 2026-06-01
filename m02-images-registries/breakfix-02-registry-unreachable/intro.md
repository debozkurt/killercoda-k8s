# M02 — Break/fix 02: Registry Unreachable

> Pre-req: the M02 baseline tour. You've seen `ErrImageNeverPull` (breakfix-01); this is a *real* pull attempt that fails.

`account-provisioner` in `provisioning` won't start. Tenant onboarding is stalled. This time the status is the familiar `ImagePullBackOff` — the same status you'd get from a wrong password, a typo'd tag, or a missing image. That's the trap: `ImagePullBackOff` is not a diagnosis, it's a category. Four very different causes all land here.

The discriminator is the **event message**, not the status. This scenario's message points at a specific branch of the differential: the kubelet tried to pull, but couldn't even *reach* the registry — the host doesn't resolve. No 401 (it never got far enough to authenticate), no `manifest unknown` (it never got far enough to ask about a manifest). Just "no such host."

Your job: resist "it's an image pull problem, must be the secret," read the actual error, identify it as a reachability failure, and fix the reference. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
