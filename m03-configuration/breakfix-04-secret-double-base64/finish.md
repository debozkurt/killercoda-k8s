# Done

You diagnosed a workload that was `Running`, `Ready`, and wrong. No status, no event, no log pointed at it — the only way to find it was to read the value the container actually got (`printenv DB_PASSWORD`) and recognize that a credential shaped like base64 had been encoded one time too many. A Secret's `data` is already base64, so a hand-encoded-twice value survives the kubelet's single decode as still-encoded garbage. You fixed it by letting `--from-literal` (or `stringData`) do the encoding once — and rolled the consumer, because env is frozen and the Secret fix alone wouldn't reach the running Pod.

That completes the four ways config breaks a workload — won't start (env), won't start (volume), won't update, and runs-but-wrong. The through-line: **read the status and events for the first three; for the fourth, you have to read the value itself, because a green Pod can still hold the wrong config.**

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § "ConfigMaps and Secrets" (base64) and § "When config breaks the Pod".
- Keeping Secrets *actually* secret at scale — encryption at rest, External Secrets, Vault, sealed-secrets — is **M11 (Security II)**. M10 covers who's allowed to read them (RBAC).
