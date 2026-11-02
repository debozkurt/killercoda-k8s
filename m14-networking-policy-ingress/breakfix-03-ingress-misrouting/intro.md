# M14 — Break/fix 03: Ingress misrouting

> Pre-req: the M14 baseline tour. You saw a healthy Ingress route to portal-ui. Here the same route returns 503.

The admin portal is down from the outside. Requests for portal.polyphone.example return `503 Service Temporarily Unavailable`. The backend looks healthy. The portal-ui Pods are Running and Ready. The Service has a ClusterIP and lists endpoints. A call to the Service directly succeeds.

The Service works and the controller runs, so the break sits in the Ingress rule that joins them. A 503 means the controller matched a rule and had no backend to receive the request. This is an L7 failure, and the status code tells you which half to inspect.

Your job: reproduce the 503, read the rule against the Service it names, and find the one field that does not line up.

The cluster and the controller take 2–4 minutes to start. Click **Start** when ready.
