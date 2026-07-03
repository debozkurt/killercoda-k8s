# Done

You read a healthy PKI end to end: **cert-manager** and the two-step internal CA (a SelfSigned bootstrap issuer → the CA `Certificate` → the CA `ClusterIssuer`), a leaf `Certificate` reconciled into a `kubernetes.io/tls` Secret (and its SANs, decoded straight from the cert), a working **mTLS** call between `config-client` and `config-api` — plus the rejection when a caller brings no client cert — and a cert's expiry with cert-manager's automatic renewal. That's the shape of "secured": issued, correctly named, mutually trusted.

**Next:**

- For the *why* — the three-layer model (issuance / identity / trust), the cert-manager issuance chain, SANs vs CN, trust distribution, and where ACME fits — read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order — each knocks out exactly one layer:
  - **`breakfix-01-certificate-not-ready`** — a `Certificate` that won't issue (bad `issuerRef`), so its Secret is never written and the server Pod is stuck. **Issuance.**
  - **`breakfix-02-san-mismatch`** — a cert that issues fine but omits the name clients dial, so the handshake fails hostname verification. **Identity.**
  - **`breakfix-03-trust-mismatch`** — a valid, correctly-named server cert the client rejects because it trusts the wrong CA. **Trust.**
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
