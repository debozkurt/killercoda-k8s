# Done

A Pod stuck `ContainerCreating` sent you not to the Pod but to what it mounts. The `FailedMount` named a Secret that didn't exist; the Secret didn't exist because its `Certificate` read `Ready: False`; and the `CertificateRequest` beneath it named the real reason — an `issuerRef` pointing at an issuer that doesn't exist. Repointing it at `polyphone-ca` let cert-manager sign the cert, write the Secret, and unstick the Pod.

The reflex: **a missing cert is a missing Secret is a stuck Pod.** When a workload can't mount a `tls` Secret, don't debug the workload — climb the issuance ladder: `Certificate` (is it `Ready`?) → `CertificateRequest` (why not?). The answer is almost always an issuer that's missing, the wrong `kind`, or not itself `Ready`.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why* — the cert-manager issuance chain and the `Issuer`/`Certificate`/`CertificateRequest` objects — see [`LESSON.md`](../LESSON.md) § cert-manager and the issuance chain.
- Then `breakfix-02-san-mismatch`: a cert that issues perfectly but claims the wrong name.
