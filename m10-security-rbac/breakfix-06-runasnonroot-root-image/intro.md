# M10 — Break/fix 06: runAsNonRoot — a root image

> Pre-req: break/fix 04. You have seen admission reject a Pod before it existed. This Pod passed admission.

The `payments` namespace enforces the **restricted** Pod Security Standard. The team learned from the last incident: `ledger-sync` ships with `runAsNonRoot`, a seccomp profile, no privilege escalation, and all capabilities dropped. PodSecurity admission accepted the Pod.

The Deployment still reports `0/1`. Unlike break/fix 04, a Pod exists, and its container never starts. Find which component refused the container and what it checked.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
