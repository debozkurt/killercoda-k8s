# M20 — Break/fix 01: Validation Rejects a Rollout

> Pre-req: the M20 baseline tour. You've seen `require-resource-limits` admit a compliant workload; this is the same policy rejecting one that isn't.

A new tenant service, `billing-api`, was deployed to `tenant-apps` and never came up. `kubectl get deploy -n tenant-apps` shows it `0/1`. But this isn't the usual `Pending`/`ImagePullBackOff` — run `kubectl get pods -n tenant-apps` and there are **no `billing-api` Pods at all**, not even a failing one. There's nothing to `logs`, nothing to `describe` at the Pod level, because no Pod was ever created.

That's the fingerprint of an **admission** rejection of a controller-created Pod (M10 taught it for PodSecurity): the Deployment and its ReplicaSet exist, but every time the ReplicaSet tries to create a Pod, admission says no — so the count stays at zero and the reason lives on the ReplicaSet, not on any Pod. Here the gate isn't PodSecurity; it's a Kyverno `ClusterPolicy`.

Your job: find the `FailedCreate` event and read the denial, identify which policy and rule rejected the Pod, then make the workload comply. The cluster plus Kyverno take about 2–4 minutes to come up. Click **Start** when ready.
