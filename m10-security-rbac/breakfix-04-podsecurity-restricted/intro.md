# M10 — Break/fix 04: PodSecurity — a rejected Pod

> Pre-req: break/fix 01 to 03. Those were authorization denials. This one comes from a different gate: admission.

The security team created a namespace, `payments`, that enforces the **restricted** Pod Security Standard. A workload, `payments-api`, was rolled out into it. The Deployment reports `0/1` ready. `kubectl get pods -n payments` prints nothing: no `Pending` Pod, no crash loop, nothing to describe.

Find where the refusal is recorded, read which fields it demands, and give the Pod a `securityContext` that meets `restricted`.

The cluster takes 60–120 seconds to come up. Click **Start** when ready.
