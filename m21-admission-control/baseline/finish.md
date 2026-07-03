# Done

You toured raw admission webhooks working. A minimal `admission-guard` server runs in the `admission` namespace, and two objects register it in the API server's write path: a `MutatingWebhookConfiguration` (path `/mutate`, injects `env=tenant`) and a `ValidatingWebhookConfiguration` (path `/validate`, requires `env`). Both call the server over HTTPS, verifying its certificate against the `caBundle`; both are scoped to `tenant-apps` with `failurePolicy: Fail`.

Internalize the three facts before you break them:

- **Order is fixed:** all mutating webhooks run, then all validating ones — so a bare Pod is admitted because mutate injects `env` before validate checks for it. The stored object differs from the manifest.
- **`failurePolicy` is blast radius:** `Fail` fails closed (a down backend blocks writes in scope); the scope (`rules` + `namespaceSelector`) is what keeps that blast radius off the fleet and the control plane.
- **A webhook touches exactly what its scope says:** `tenant-apps` gets mutated, `default` doesn't — one label on the namespace is the whole difference.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order:
  - **`breakfix-01-webhook-fail-closed`** — a Deployment stuck at `0/N`; the webhook backend is down and `failurePolicy: Fail` blocks its Pods.
  - **`breakfix-02-mutation-not-firing`** — another `0/N`, but this time a validating *denial*: the mutating webhook stopped firing, so the label it should inject is missing.
  - **`breakfix-03-webhook-scope-too-broad`** — a workload in `signaling` stuck `0/N`, rejected by a webhook that only governs `tenant-apps`.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
