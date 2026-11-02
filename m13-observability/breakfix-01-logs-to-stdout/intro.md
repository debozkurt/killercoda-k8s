# M13 — Break/fix 01: an app that writes to a file

> Pre-req: the M13 baseline tour. There you read `kubectl logs` on a workload that logs to stdout. This one does not.

A new workload, `session-logger`, runs in the `app-services` namespace and records per-session activity. It is Running 1/1 and healthy by every status check. When the on-call engineer ran `kubectl logs`, one startup line came back and nothing else. The app is working, and you cannot see what it does.

Your job: find why a healthy Pod has an empty log, then make its activity appear in `kubectl logs`. The one line it prints is the clue. This is the container logging contract: what the kubelet captures, and what it does not.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
