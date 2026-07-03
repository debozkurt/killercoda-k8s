# M21 — Baseline Tour

M20 gave you a policy engine — Kyverno — as a working front door and hid how it plugged into the API server. It registered **admission webhooks**. This module opens that box: the raw `MutatingWebhookConfiguration` and `ValidatingWebhookConfiguration` objects that splice an HTTPS callback of your own into the write path, after RBAC and before the object is stored. Every policy engine, sidecar injector, and CA injector is built on exactly these two objects.

This tour runs on the full Polyphone fleet plus one addition the setup applies for you: a minimal webhook server, **`admission-guard`**, in a new `admission` namespace, and the two configurations that register it against a governed `tenant-apps` namespace. The server serves two paths:

- **`/mutate`** — injects the label `env=tenant` onto a Pod that lacks it (the mutating phase)
- **`/validate`** — requires every Pod to carry an `env` label (the validating phase)

Because mutating webhooks run before validating ones, a Pod submitted with **no** `env` label is admitted anyway: the mutating webhook adds it, and the validating webhook then sees it. A compliant `tenant-web` Deployment is already up to prove exactly that.

Three short steps:

1. **The webhook backend and its two configurations** — `admission-guard` running, and the two webhook objects reading their `clientConfig`, `rules`, `namespaceSelector`, and `failurePolicy`
2. **Mutate then validate admits a bare Pod** — `tenant-web`'s Pod carries an `env` label its manifest never set, injected at admission
3. **failurePolicy and scope: the blast radius** — the webhook is `Fail` (fails closed) but scoped to `tenant-apps` only, so the fleet is untouched

Nothing to fix here. See what raw webhook admission looks like before the break/fix scenarios snap each control. The cluster plus the webhook take about 2–4 minutes to come up. Click **Start** when ready.
