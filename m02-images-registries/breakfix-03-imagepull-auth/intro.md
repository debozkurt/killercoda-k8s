# M02 — Break/fix 03: 401 Unauthorized

> Pre-req: the M02 baseline tour (the private registry + `imagePullSecret` model), and breakfix-02 (reading the event to classify a pull failure).

`media-recorder` in `media` is in `ImagePullBackOff`. Call recording is degraded. Same status as the last scenario — but this time the registry is reachable and the failure is different.

`media-recorder` pulls its proprietary image from the in-cluster private registry at `localhost:5000`, which requires authentication. The pod has no `imagePullSecret`, so the kubelet's pull is **anonymous** — and the registry answers `401 Unauthorized`. The kubelet reached the registry, the registry replied, and the reply was "no." That's the auth branch of the differential: not "couldn't reach" (breakfix-02), not "wouldn't try" (breakfix-01) — *reached and rejected*.

Your job: read the `401` in the events, recognize it as an authentication failure rather than a missing image or unreachable host, and wire the credentials the kubelet needs. The cluster takes 90–150 seconds to come up (it also stands up the private registry). Click **Start** when ready.
