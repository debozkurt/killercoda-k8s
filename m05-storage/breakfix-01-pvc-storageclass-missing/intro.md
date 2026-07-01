# M05 — Break/fix 01: PVC Won't Bind (Missing StorageClass)

> Pre-req: the M05 baseline tour. You've seen a `Bound` claim and a healthy `WaitForFirstConsumer` `Pending`; this is a `Pending` that *is* broken.

`cdr-writer` in `cdr-storage` — the workload that persists Call Detail Records — never came up. `kubectl get pods -n cdr-storage` shows it `Pending`, and it's been that way since the cluster started. There are no logs (the container never ran) and nothing is crashing. The Pod is simply waiting.

Waiting on what? A Pod that mounts a PVC will not start until that claim is `Bound`. So the diagnosis isn't in the Pod — it's in the claim, one object over. This is the first leaf of the storage differential: the claim can't get a volume.

Your job: resist describing the Pod in circles, run `get pvc`, read *why* the claim is stuck, and fix the class it's asking for. The cluster takes up to ~2–3 minutes to come up (one workload stays Pending by design). Click **Start** when ready.
