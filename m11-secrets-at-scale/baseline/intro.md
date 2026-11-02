# M11 — Baseline Tour

At scale nobody writes a Secret by hand. A controller **materializes** it from a source of truth, and the Pod reads the result.

This tour runs that pipeline on the Polyphone fleet. A backing store, the Secret `vault-backend` in the `secrets-source` namespace, stands in for an external secrets manager. A **`SecretSync`** custom resource models an External Secrets Operator `ExternalSecret`: it names store keys and holds no values. The **`secret-operator`** reconcile loop reads the store, writes one Kubernetes Secret per `SecretSync`, and reports the result in `.status`. Two consumers read those Secrets as environment variables: `billing-processor` in `provisioning` and `partner-connector` in `media`.

The operator is a small `kubectl` loop, not a compiled controller. The pipeline, the status you read, and the failure modes match the real tools.

The cluster runs on **2 nodes** (one tainted control-plane node, one worker). Nothing is broken.

Six steps:

1. **The inputs**: the store and the SecretSyncs that name keys in it
2. **The derived Secret**: what the operator wrote, and how to tell it from a hand-written Secret
3. **The operator's report**: sync status and logs
4. **The consumer**: the value traced from the store to the running process
5. **Prove it is derived**: hand-edit the Secret and watch the operator revert it
6. **Prove what etcd holds**: read the Secret straight from etcd

The cluster takes 90–150 seconds to come up. Click **Start** when ready.
