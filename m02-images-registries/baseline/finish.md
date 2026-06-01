# Done

You toured the mechanics of turning an image *name* into image *bytes* on a node: the four parts of a reference, the difference between a mutable tag and an immutable digest, how `imagePullPolicy` and the node cache decide whether the kubelet pulls, and a healthy authenticated pull from a private registry via an `imagePullSecret`. That's the shape of "healthy" — internalize it so each broken link stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the four break/fix scenarios, in order — together they walk the **pull-failure differential** top to bottom, one kubelet message each:
  - **`breakfix-01-never-pull`** — `ErrImageNeverPull`: the kubelet *wouldn't* pull (policy).
  - **`breakfix-02-registry-unreachable`** — `ImagePullBackOff` / `no such host`: it *couldn't reach* the registry.
  - **`breakfix-03-imagepull-auth`** — `401 Unauthorized`: the registry *rejected* the credentials.
  - **`breakfix-04-digest-mismatch`** — `manifest unknown`: the reference resolved to *nothing*.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
