# Done

Nothing in the pipeline was broken — that was the lesson. The store rotated, the operator synced the new value, every SecretSync read `Synced`, and the `db-credentials` Secret held the current password. But `billing-processor` consumes that Secret as an environment variable, frozen at container start (M03), and it had been running since before the rotation — so it kept presenting the old credential while every status stayed green. Rolling the Deployment gave it a fresh container that re-read the Secret, and the new value finally reached the process.

Two things worth keeping: **rotation is two steps, not one** — updating the Secret and getting consumers to adopt it are separate, and an env-consumer never adopts a change on its own; and **a green pipeline can sit above a wrong workload** — when the supply chain is healthy but the app is misbehaving on a credential, stop reading the pipeline and read the value the *process* holds (`kubectl exec … printenv`), because the failure is past the last green status. The durable fix is to couple the two steps by construction — a config-hash annotation or a reloader controller — so "the secret changed" always drags "the consumers restarted" along with it.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Rotation: the Secret updates, the Pod doesn't.
- You've worked all three links of the materialization chain — the reference, the store, and the consumer. Revisit [`LESSON.md`](../LESSON.md) § Production thinking to tie them together.
