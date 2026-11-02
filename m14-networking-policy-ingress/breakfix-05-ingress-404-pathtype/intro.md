# M14 — Break/fix 05: Ingress 404 from pathType

> Pre-req: the M14 baseline tour and break/fix 03. You read a 503 as a backend problem. This scenario returns a 404.

The admin portal loads at portal.polyphone.example, but any deep link returns `404 Not Found`. The portal-ui Pods are Ready and its Service has endpoints. A call to the Service for the same path succeeds.

A 404 from the controller means no rule matched the request. The host matches. The path does not. The rule's pathType decides how the path matches, and a wrong choice makes the backend look broken when it is not.

Your job: prove that the backend serves the path, read the rule, and change the one field that rejects the request.

The cluster and the controller take 2–4 minutes to start. Click **Start** when ready.
