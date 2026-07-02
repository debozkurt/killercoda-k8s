# M14 — Break/fix 03: Ingress Misrouting

> Pre-req: the M14 baseline tour. You've seen a healthy Ingress route to `portal-ui`; this is the same route returning `503`.

The admin portal is down from the outside. Requests to `portal.polyphone.example` come back `503 Service Temporarily Unavailable`. But the backend looks completely healthy: `portal-ui`'s Pods are `Running` and `Ready`, its Service has a ClusterIP, and `kubectl get endpoints portal-ui -n admin-portal` lists the Pod IPs. Reach `portal-ui` directly by its Service and it answers fine.

So the Service works and the controller is up — the break is in the Ingress rule that connects them. A `503` from an Ingress means the controller matched the request to a rule but had no healthy backend to forward it to. That's a different failure from the NetworkPolicy timeouts: this one is L7, north-south, and the controller is telling you *exactly* which half is wrong.

Your job: reproduce the `503`, read the Ingress rule against the Service it names, and find the one field that doesn't line up. The cluster plus the ingress controller take about 2–4 minutes to come up. Click **Start** when ready.
