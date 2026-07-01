# Done

`cdr-writer` was stuck `Pending` with no logs and nothing crashing — because its PVC couldn't bind. The claim named a StorageClass (`fast-ssd`) that doesn't exist, so no provisioner ran and no volume was ever created. `get pvc` showed the claim `Pending`; `describe pvc` named the cause outright. The fix meant working around an immutable field: `storageClassName` can't be edited, so you deleted and recreated the claim with the real class, and `WaitForFirstConsumer` bound it the moment a Pod consumed it.

That's the first leaf of the storage differential: **a Pod stuck on storage is a claim that isn't `Bound` — read the claim, not the Pod.** Same "the headline lies" instinct as M04's empty EndpointSlice, one layer down.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § The claim/volume split, and dynamic provisioning.
- Next scenario: **`breakfix-02-pvc-claim-missing`** — this time the claim isn't `Pending`. It isn't there at all.
