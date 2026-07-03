# Done

You toured a policy engine working. Kyverno runs in the `kyverno` namespace as four controllers, the admission one registering the validating and mutating webhooks the API server calls during admission. Three `ClusterPolicy` objects, scoped to `tenant-apps`, did three different jobs: **require-resource-limits** admitted `tenant-web` (it declares limits) and denied a no-limits Pod; **add-owner-label** rewrote `tenant-web`'s Pod at admission to carry `owner=platform`; **disallow-latest-tag** refused a `:latest` image while passing the pinned `nginx:1.25`.

Internalize the three signatures before you break them:

- a **validation** rejection is `admission webhook … denied the request`, naming the policy and rule — a policy event, not a workload bug
- a **mutation** shows up as a field on the live object that isn't in the manifest — and it only happens at admission
- an **image** rejection names the image rule, distinct from a limits rejection

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order:
  - **`breakfix-01-require-limits-rejected`** — a Deployment stuck at `0/N`; the validate rule rejected its Pods.
  - **`breakfix-02-mutation-not-applied`** — a workload that runs but is missing its injected label; the mutate policy matched the wrong namespace.
  - **`breakfix-03-image-tag-rejected`** — another `0/N` Deployment; its image is pinned to `:latest`.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
