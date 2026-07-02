# M14 — Break/fix 01: NetworkPolicy Default-Deny

> Pre-req: the M14 baseline tour. You've seen a default-deny plus an allow working together; this is the deny with the allow missing.

`session-broker` in the `media` namespace has gone dark. Callers that reached it yesterday now time out — the requests just hang. But everything the usual checks look at is healthy: `kubectl get pods -n media` shows `session-broker` `Running` and `Ready`, `kubectl get endpoints session-broker -n media` lists its Pod IPs, and DNS for `session-broker.media` resolves fine. Nothing is crashing, nothing is refused.

A hang like this — DNS fine, endpoints present, connection neither refused nor answered — is the NetworkPolicy signature. Someone tightened `media` with a default-deny for ingress as a security hardening step, and never added the allow that lets the legitimate callers back in. The deny is doing exactly what it says; the mistake is what's *missing*.

Your job: recognize the timeout for what it is, find the policy, and restore access — the right way, by adding the allow, not by tearing down the deny. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
