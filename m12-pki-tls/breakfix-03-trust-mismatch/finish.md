# Done

The server's cert was issued, `Ready`, and correctly named — flawless — and the call still failed, because trust lives on the *client's* side. `unable to get local issuer certificate` meant the client couldn't chain the server's cert up to any CA it held. The server was signed by `polyphone-internal-ca`; the client was mounting `polyphone-legacy-ca`. Pointing its trust volume at `internal-ca-bundle` gave it the right anchor, and the same untouched server cert verified immediately.

The reflex: **trust is the client's CA, distributed separately from the cert — and you fix a trust error by distributing the *right* CA, never by turning verification off.** Split the error first (`unable to get local issuer certificate` = trust; `subject name matches` = identity), then compare the server cert's *issuer* against the CA the client actually holds. `curl --insecure` / `insecureSkipVerify` makes the error vanish by making the check meaningless — that's how internal TLS quietly rots into unauthenticated plaintext-equivalent.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why* — the chain of trust, distributing `ca.crt`, and trust-manager at scale — see [`LESSON.md`](../LESSON.md) § Trust.
- That's all three break/fix scenarios — issuance, identity, trust. Re-read [`LESSON.md`](../LESSON.md) for the full model, including where ACME and public certs fit.
