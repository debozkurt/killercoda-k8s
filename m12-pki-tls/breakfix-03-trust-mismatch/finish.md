# Done

The server cert was issued, Ready and correctly named, and the call still failed. Trust lives on the client's side. `unable to get local issuer certificate` meant the client could not chain the server cert to any CA it held. The internal CA signed the server, and the client mounted the legacy CA. Pointing the `trust` volume at `internal-ca-bundle` fixed it. The server cert never changed.

The instinct to keep: split the error first. `unable to get local issuer certificate` is trust. `subject name matches` is identity. For trust, compare the issuer of the server cert with the CA the client holds. Never answer a trust error with `--insecure`.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Read [`LESSON.md`](../LESSON.md) § Trust.
- Continue to `breakfix-04-issuer-not-ready`: two Certificates fail at once.
