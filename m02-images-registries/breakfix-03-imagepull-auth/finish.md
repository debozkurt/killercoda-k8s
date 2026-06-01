# Done

You diagnosed an authenticated-registry pull that the kubelet was making anonymously. The status was the same `ImagePullBackOff`; the event message — `401 Unauthorized` — placed it on the auth branch: the registry was reachable and answered, but rejected the request for missing credentials. You created a `docker-registry` secret in the right namespace, matched it to the registry host, and attached it so the kubelet authenticates.

This is the failure most likely to hit a real fleet, and the most likely to hit *all at once*: a rotated credential breaks nothing until pods restart and re-pull. The ANSWER-KEY's production-thinking section is worth reading for that blast-radius angle.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § "Pulling from a private registry".
- Last scenario: **`breakfix-04-digest-mismatch`** — the registry is reachable and the credentials are fine, but the reference resolves to nothing.
