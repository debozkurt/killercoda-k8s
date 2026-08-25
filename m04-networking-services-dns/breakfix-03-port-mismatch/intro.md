# M04 — Break/fix 03: Port Mismatch

> Pre-req: breakfix-02. You've seen an empty EndpointSlice; this one is full, and the connection *still* fails.

The admin portal is down — `portal-ui` in `admin-portal` refuses every connection. Your first instinct after the last scenario is right: check the endpoints. But this time the EndpointSlice for `portal-ui` is **populated** — the Pods are there, Ready, and in the EndpointSlice. The traffic is reaching a Pod and getting bounced.

That rules out the black hole and points somewhere new. A connection that's *refused* (not dropped) means it got to a Pod, and the Pod's kernel sent it back — because nothing is listening on the port the Service delivered it to. This is the `port` / `targetPort` / `containerPort` distinction made painful.

Your job: read the populated EndpointSlice as the clue it is, find the port the Service forwards to versus the port the process actually listens on, and reconcile them. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
