# Done

You diagnosed a Pod that never started because its configuration couldn't be assembled. `CreateContainerConfigError` is the signature of an `env`/`envFrom` reference that points at a ConfigMap/Secret or a key that doesn't exist — and the describe event names the exact missing piece (`couldn't find key MAX_CONNECTIONS in ConfigMap media/app-config`). You fixed the side that was wrong: the reference, the ConfigMap, or — where a fallback is acceptable — marking it `optional`.

That's the env-injection failure. The next one is the *same* root cause — a missing referenced object — but consumed as a volume, which fails at a completely different lifecycle phase and shows a completely different status.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § "When config breaks the Pod".
- Next scenario: **`breakfix-02-secret-volume-missing`** — a Pod stuck in `ContainerCreating`, mounting a Secret that was never created.
