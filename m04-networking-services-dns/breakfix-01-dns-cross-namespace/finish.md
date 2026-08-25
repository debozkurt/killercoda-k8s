# Done

You separated "the Service is down" from "the name doesn't resolve from here." The Pod was `Running`, `get svc` in `media` showed a healthy Service — and the call still failed, because a bare name is only tried under the *caller's* namespace. Reproducing the lookup from `provisioning` (not `media`) is what made the NXDOMAIN visible; qualifying the name to `<svc>.<ns>` fixed it.

That instinct — **resolve the name from the namespace that's actually asking, and read the DNS answer** — is the first leaf of the connectivity differential.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Cluster DNS.
- Next scenario: **`breakfix-02-selector-mismatch`** — the name resolves fine, but the Service has no backends at all.
