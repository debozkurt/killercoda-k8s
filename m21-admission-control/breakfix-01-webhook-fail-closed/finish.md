# Done

You read a `0/N`-with-no-Pods for what it is: not a scheduling or image failure, but an **admission** rejection of the Pods a ReplicaSet keeps trying to create. The reason lived on the ReplicaSet's `FailedCreate` event — and the exact words mattered. It said **`failed calling webhook`**, not `denied the request`: the API server never reached the backend, so there was no policy verdict at all. `admission-guard` had zero Pods and its Service had no endpoints, and the webhook's `failurePolicy: Fail` turned that unreachable call into a rejection. The fix was to restore the *backend*, not touch the workload or the configuration.

The reflexes to carry:

- **`failed calling webhook` ≠ `denied the request`.** The first is infrastructure (unreachable or untrusted server — check the backend Pods, endpoints, and the cert/`caBundle`); the second is policy (the server said no — read the message). Reading the wrong one sends you fixing a workload that was never the problem.
- **`failurePolicy: Fail` fails closed.** A down webhook blocks every write in its scope. That is the safe posture for a control you must not bypass — and the reason the blast radius (the `rules` + `namespaceSelector` that kept this to `tenant-apps`) is what stops a dead backend from wedging the whole cluster.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § failurePolicy: fail closed, fail open, and blast radius.
- Then **`breakfix-02-mutation-not-firing`** — another `0/N`, but this time it *is* a denial: the mutating webhook stopped firing, so the label validation requires is never injected.
