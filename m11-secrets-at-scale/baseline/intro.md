# M11 — Baseline Tour

In M03 a Secret was a leaf: you wrote it, a Pod read it. That doesn't survive GitOps — base64 is not encryption, so a plaintext Secret can't be committed to Git. At scale a Secret stops being a thing you write and becomes a thing a controller **materializes** from an external source of truth.

This tour runs that pipeline on the Polyphone fleet. A backing store — `vault-backend`, a Secret in the `secrets-source` namespace — stands in for an external secrets manager like Vault. A **`SecretSync`** custom resource (modeling an External Secrets Operator `ExternalSecret`) *names* which store keys to pull, without containing them, so it is safe to commit. The **`secret-operator`** reconcile loop reads the store, materializes a Kubernetes `Secret` for each SecretSync, and reports the result in `.status`. Two consumers — `billing-processor` (`provisioning`) and `partner-connector` (`media`) — then read those materialized Secrets as ordinary env vars, never knowing the operator exists.

The operator is a legible, offline stand-in for ESO — a small kubectl reconcile loop rather than a compiled controller — but the pipeline, the `.status` you read, and the ways it fails are the real thing.

This runs on the full Polyphone fleet on a **2-node cluster** (one tainted control-plane, one worker), plus the store, the CRD, the operator, and two healthy syncs. Nothing is broken — you're learning to *read* a working secrets pipeline before the break/fix scenarios snap a link.

Four short steps:

1. **The inputs** — the backing store and the SecretSyncs that name keys from it
2. **The materialized Secret** — the derived object the operator produced, and why editing it by hand is pointless
3. **The operator reconciling** — reading the sync result from `.status` and the operator's logs
4. **The consumer** — the chain end to end, from store value to running process

See what a healthy pipeline looks like, so a broken link stands out later. The cluster takes 90–150 seconds to come up (the operator needs a few extra seconds to materialize both Secrets). Click **Start** when ready.
