# M21 — Break/fix 02: A Mutating Webhook That Never Fires

> Pre-req: the M21 baseline tour. You've seen mutate-then-validate admit a bare Pod. This is what happens when the mutating half silently stops running.

A tenant workload, `orders-api`, was deployed to `tenant-apps` and never came up — `0/1`, and `kubectl get pods -n tenant-apps` shows **no `orders-api` Pods**. Same `0/N`-with-no-Pods shape as break/fix 01, so start the same way: read the ReplicaSet's `FailedCreate` event.

This time the message is different. It is `admission webhook "validate.admission-guard.polyphone.example" denied the request: admission-guard: object is missing required label 'env'`. That is a genuine **`denied the request`** — the webhook was reached, and it said no because the Pod has no `env` label.

Here's the catch: the author *never sets* an `env` label. In the baseline, they didn't have to — the **mutating** webhook injects it before validation runs. So the real question isn't "why is the label missing from the manifest" (it always was); it's "why didn't the mutating webhook add it this time?" The denial is at validation, but the fault is upstream, in mutation. Your job: read *both* webhook configurations, find why the mutating one stopped firing, and fix it so mutation supplies what validation requires. Click **Start** when ready.
