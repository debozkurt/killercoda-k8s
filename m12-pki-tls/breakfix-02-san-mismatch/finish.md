# Done

A healthy Pod, a `Ready` cert, and an existing Secret — yet the call failed, and the *error message* pointed straight at the cause. `no alternative certificate subject name matches target host name` is the hostname check, not the trust check: the cert was issued and trusted, but its SANs listed `config-api-legacy` while clients dialed `config-api`. Restoring the real `dnsNames` (all three DNS forms of the Service), letting cert-manager reissue, and rolling nginx made the identity match the connection.

The reflex: **identity is SANs, not CN, and a green `Certificate` means *issued*, not *correct*.** When TLS fails, read the error to split trust from identity, then decode the served cert (`openssl x509 -ext subjectAltName`) and compare its SAN list to the exact name the client used. A service's cert must carry every name any caller uses — in Kubernetes, the short name, `<svc>.<ns>.svc`, and the full FQDN.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why* — SANs vs the legacy Common Name and hostname verification — see [`LESSON.md`](../LESSON.md) § Certificate identity.
- Then `breakfix-03-trust-mismatch`: a cert that's issued *and* correctly named, rejected because the client trusts the wrong CA.
