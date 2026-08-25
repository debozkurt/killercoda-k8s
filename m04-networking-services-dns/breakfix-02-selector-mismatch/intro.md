# M04 — Break/fix 02: Selector Mismatch

> Pre-req: the M04 baseline tour. You've seen a healthy EndpointSlice; this is an empty one.

Calls to `route-engine` in `call-routing` are failing — routing decisions aren't getting answered. But every obvious thing looks fine: `kubectl get pods` shows the `route-engine` Pods `Running` and `Ready`, and `kubectl get svc route-engine` shows a normal ClusterIP and port. Nothing is crashing, nothing is `ImagePullBackOff`, nothing is logging an error.

This is the black hole. A Service can look completely healthy and route to *nothing*, because the one object that actually carries traffic — its EndpointSlice — is empty. The headline `get svc` lies; the truth is one command over.

Your job: resist restarting the healthy Pods, check the endpoints, and find why the Service has no backends. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
