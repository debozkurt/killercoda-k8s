# Done

A healthy Pod, a Ready cert and an existing Secret failed the call anyway, and the error named the cause. `no alternative certificate subject name matches target host name` is the name check, not the trust check. The cert listed `config-api-legacy`, and clients dialed `config-api`. You restored the `dnsNames`, waited for the reissue, and rolled nginx so it loaded the new cert.

The instinct to keep: Ready means issued, not correct. Split trust from identity with the error text. Then decode the served cert and compare its SANs with the exact name the client dialed.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Read [`LESSON.md`](../LESSON.md) § Certificate identity.
- Continue to `breakfix-03-trust-mismatch`: a client that trusts the wrong CA.
