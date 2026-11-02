# Done

You read a healthy PKI end to end. **cert-manager** and a two-step internal CA (a SelfSigned bootstrap issuer, the CA `Certificate`, the CA `ClusterIssuer`) signed a leaf `Certificate`, and cert-manager reconciled it into a `kubernetes.io/tls` Secret. You decoded the SANs straight from the cert and watched an **mTLS** call succeed. A caller with no client cert got a 400. You read the validity window and the scheduled renewal, then deleted the Secret and watched the controller rebuild it. That is the shape of "secured": issued, correctly named, mutually trusted.

**Next:**

- Read [`LESSON.md`](../LESSON.md) for the three-layer model (issuance, identity, trust), the cert-manager issuance chain, SANs, trust distribution and ACME.
- Work the five break/fix scenarios in order. Each knocks out one layer:
  - **`breakfix-01-certificate-not-ready`**: a `Certificate` names an issuer that does not exist. **Issuance.**
  - **`breakfix-02-san-mismatch`**: the cert issues, but it omits the name clients dial. **Identity.**
  - **`breakfix-03-trust-mismatch`**: the client trusts the wrong CA. **Trust, client side.**
  - **`breakfix-04-issuer-not-ready`**: the issuer exists but cannot sign. **Issuance, one rung deeper.**
  - **`breakfix-05-client-cert-purpose`**: the server rejects a client cert issued for the wrong purpose. **mTLS, server side.**
- Check each path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
