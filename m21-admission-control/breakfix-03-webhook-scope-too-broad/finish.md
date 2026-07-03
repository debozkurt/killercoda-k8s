# Done

You read a denial for what it *placed*, not just what it said. The message — a missing `env` label — was identical to break/fix 02, but it landed in `signaling`, a namespace the `admission-guard` webhook was never meant to govern. Its `namespaceSelector` had been widened to `{}`, which matches *every* namespace, so it reached across the whole cluster; the mutating webhook was still correctly scoped to `tenant-apps`, so nothing injected `env` in `signaling`, and the Pod was rejected. The fix was to narrow the validating webhook's `namespaceSelector` back to `admission-guard=enabled` — scoping the webhook, not weakening it.

The reflexes to carry:

- **A webhook touches exactly what its `rules` and selectors say — no more, no less.** When a webhook rejects objects in a namespace it has no business in, read its scope first. An empty `namespaceSelector: {}` matches everything, including `kube-system`.
- **The tell is often *where*, not *what*.** Two scenarios can share a denial string and have completely different causes. The namespace the denial lands in — governed vs collateral — points you at scope versus logic.
- **Prefer positive selectors.** Scoping to namespaces that carry a label fails safe: an unlabeled namespace is never intercepted, so a mistake shrinks the blast radius instead of growing it. Widening to `{}` does the opposite.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Registering a webhook and § failurePolicy: fail closed, fail open, and blast radius.
- You've now worked all three: a failed call (01), a mutation gap (02), and an over-broad scope (03). Re-read [`LESSON.md`](../LESSON.md) end to end to tie the machinery together.
