# M02 — Break/fix 01: ErrImageNeverPull

> Pre-req: the M02 baseline tour, or comfort with `imagePullPolicy` and the node image cache.

A deploy went out to `analytics` and the `metrics-aggregator` pod never came up. Telemetry dashboards are going stale. The on-call's first instinct — `kubectl logs` — returns nothing: the container has never run, so there's nothing to log.

This is the first branch of the **pull-failure differential**, and it's the odd one out: the status isn't `ImagePullBackOff`. It's `ErrImageNeverPull` — which means the kubelet didn't *fail* to pull, it *refused* to even try. No registry was contacted, no network request was made, no backoff is in progress. Something in the pod spec told the kubelet "do not pull this," and the image it needs isn't on the node.

Your job: recognize that this is "wouldn't pull," not "couldn't pull" — a completely different cause from the auth and reachability failures in the later scenarios — and get the pod running. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
