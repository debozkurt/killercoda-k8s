# M21 — Break/fix 01: A Fail-Closed Webhook Wedges Deploys

> Pre-req: the M21 baseline tour. You've seen the two webhooks admit a compliant workload; this is what happens when the backend they call is down and `failurePolicy` is `Fail`.

A new tenant service, `billing-api`, was deployed to `tenant-apps` and never came up. `kubectl get deploy -n tenant-apps` shows it `0/1`. But this isn't `Pending` or `ImagePullBackOff` — `kubectl get pods -n tenant-apps` shows **no `billing-api` Pods at all**, not even a failing one. Nothing to `logs`, nothing to `describe` at the Pod level, because no Pod was ever created.

That's the fingerprint of an **admission** rejection of a controller-created Pod (M10 taught it for PodSecurity, M20 for a policy engine): the Deployment and ReplicaSet exist, but every time the ReplicaSet tries to create a Pod, admission says no, so the count stays at zero and the reason lives on the ReplicaSet. This time the gate is a raw admission webhook — and the reason is not a policy verdict but a *failed call*. The webhook's backend is unreachable, and its `failurePolicy` is `Fail`, so the API server treats every call it can't complete as a denial.

Your job: find the `FailedCreate` event and read it carefully — the difference between `failed calling webhook` (infrastructure: can't reach the server) and `denied the request` (policy: the server said no) is the whole diagnosis. Then restore the backend so admission calls succeed again. The cluster plus the webhook take about 2–4 minutes to come up. Click **Start** when ready.
