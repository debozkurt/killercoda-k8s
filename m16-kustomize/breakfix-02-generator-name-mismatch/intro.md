# M16 — Break/fix 02: Generator Name Mismatch

> Pre-req: the M16 baseline tour, where you watched the generator's hash suffix get rewritten into the Deployment's reference. Here that rewrite didn't happen.

The `edge-relay` prod overlay built cleanly and `apply -k` reported success — every object accepted by the API server. But the workload isn't up: its Pod is stuck, and the fleet dashboard shows `edge-relay` at `0/3`.

This is the second place Kustomize fails, and the sneakiest: **runtime**. The build was valid, the apply was valid, so nothing upstream complained. The wrongness only surfaces when the kubelet tries to start the container. The good news is that once an object is in the cluster, your normal diagnostic loop works again — `describe` has plenty to say this time.

The tree is at `/root/edge-relay`. Your job: read why the container won't start, then trace it back to what the render actually produced. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
