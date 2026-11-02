# Done

A Pod stuck in `ContainerCreating` sent you to what it mounts. The `FailedMount` event named a Secret that did not exist. The Secret did not exist because its `Certificate` read Ready False. The CertificateRequest beneath it gave the reason: an `issuerRef` that named an issuer that does not exist. Repointing it at `polyphone-ca` let cert-manager sign the cert and write the Secret.

The instinct to keep: a missing cert is a missing Secret is a stuck Pod. Climb the ladder: Pod events, then `Certificate`, then CertificateRequest.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Read [`LESSON.md`](../LESSON.md) § cert-manager and the issuance chain.
- Continue to `breakfix-02-san-mismatch`: a cert that issues but claims the wrong name.
