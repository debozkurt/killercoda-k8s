# Done

You separated `ImagePullBackOff` the *category* from its actual cause. The status alone would have sent you chasing a pull secret; the event message said `no such host`, which is a reachability failure — the registry hostname didn't resolve, so the kubelet never authenticated or asked for a manifest. The fix was the registry portion of the reference, not credentials and not the tag.

That instinct — **read the event message before deciding what kind of pull failure you have** — is the spine of this whole module. The next two scenarios share the `ImagePullBackOff` status but carry completely different messages.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § the pull-failure differential.
- Next scenario: **`breakfix-03-imagepull-auth`** — same status, but this time the registry is reachable and answers with `401 Unauthorized`.
