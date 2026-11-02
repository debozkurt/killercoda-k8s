# M14 — Break/fix 01: NetworkPolicy default-deny

> Pre-req: the M14 baseline tour. You saw a default-deny and an allow work together. Here the deny has no allow.

session-broker in the media namespace went dark. Callers that reached it yesterday now time out. Every usual check looks healthy. The Pod is Running and Ready. The Service lists endpoints. DNS resolves the name. Nothing crashes and nothing is refused. The requests hang.

That pattern is the NetworkPolicy signature. Someone locked media down with a default-deny for ingress and never added the allow that lets legitimate callers back in. The deny does what it says. The mistake is what is missing.

Your job: recognize the timeout, find the policy, and restore access. Add the allow. Do not delete the deny.

The cluster takes 60–120 seconds to start. Click **Start** when ready.
