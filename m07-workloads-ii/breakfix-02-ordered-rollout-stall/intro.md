# M07 — Break/fix 02: Ordered Rollout Stall

> Pre-req: breakfix-01. There, every Pod existed and none resolved. Here, the Pods do not all exist.

The `session-store` StatefulSet asks for **3 replicas**, and this time its governing Service is in place. The rollout never finished. `kubectl get statefulset` reports `READY 0/3`, and one Pod, `session-store-0`, exists. It is `Running` and not Ready. `session-store-1` and `session-store-2` were never created.

A Deployment with 3 replicas would have created all three Pods, and two healthy ones would serve. A StatefulSet behaves differently.

Your job: find why `session-store-0` is not Ready, explain why that one Pod keeps two others from existing, and get the set to 3/3.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
