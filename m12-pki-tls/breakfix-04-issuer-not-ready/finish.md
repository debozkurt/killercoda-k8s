# Done

Two workloads failed together because their `Certificate` objects shared one issuer, and that issuer could not sign. The `CertificateRequest` said the issuer did not have a Ready status condition. The `ClusterIssuer` then named the cause: its `secretName` pointed at a Secret that did not exist, so cert-manager could not load the CA key pair. One patch to the issuer cleared both failures.

The instinct to keep: the issuance ladder has a rung below the `CertificateRequest`. Pod events, then `Certificate`, then CertificateRequest, then issuer. Failures that start together point at the object they share.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Read [`LESSON.md`](../LESSON.md) § cert-manager and the issuance chain.
- Continue to `breakfix-05-client-cert-purpose`: a client cert the server refuses.
