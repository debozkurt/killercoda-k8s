# M10 — Break/fix 04: PodSecurity — a rejected Pod

> Pre-req: break/fix 01–03. Those were authorization (RBAC) denials. This is a different gate: admission.

The security team hardened a new namespace, `payments`, to enforce the **restricted** Pod Security Standard, and a workload — `payments-api` — was rolled out into it. The Deployment reports `0/1` ready. But when you go to debug the Pod, there is no Pod: `kubectl get pods -n payments` comes back empty. No `Pending`, no `CrashLoopBackOff`, nothing to describe.

That's the signature of an *admission* rejection: the Pod was refused before it was ever created, so the failure lives on the controller that tried to create it, not on a Pod. Your job: find the rejection, read which security fields it demands, and write a `securityContext` that satisfies `restricted`.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
