# M13 — Break/fix 01: Logs — an app that writes to a file

> Pre-req: the M13 baseline tour. You've read `kubectl logs` on a workload that logs to stdout; this one doesn't.

A new workload, `session-logger`, was rolled out to the `app-services` namespace to record per-session activity. It's `Running 1/1` and healthy by every status check — but when the on-call tried to see what it was doing, `kubectl logs` came back nearly empty: one startup line and nothing else. The app is clearly *doing* something; you just can't see it.

Your job: figure out why a healthy, running workload produces an empty log, and restore visibility so its activity shows up in `kubectl logs`. The clue is in the one line it *does* print. This is about the container logging contract — what the kubelet captures, and what it doesn't.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
