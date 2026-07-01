# Done

A Pod stuck `Pending` had one event that told you everything: `FailedScheduling … Insufficient memory`. No node had enough free memory to cover a request that had been fat-fingered from `256Mi` to `256Gi`, so the scheduler — which fits Pods by their *requests*, not their live usage — couldn't place it anywhere. The fix touched only the request; the image, the app, and the nodes were never the problem.

That reflex — **a `Pending` Pod means read `describe` / the `FailedScheduling` event first, not the logs** — is the spine of the whole module. Requests are what the scheduler fits; when they don't fit, this is the signature.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § The resource contract.
- Next scenario: **`breakfix-02-untolerated-taint`** — still `Pending`, but this time nothing is short on resources; a node is actively pushing the Pod away.
