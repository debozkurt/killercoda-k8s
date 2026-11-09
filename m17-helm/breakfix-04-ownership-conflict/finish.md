# Done

The chart rendered cleanly, and the install still failed: a Service with the same name existed without Helm ownership metadata. Helm refuses to take over an object it did not create, unless that metadata names the release. Writing the label and the two annotations let the install adopt the Service in place, with the same ClusterIP.

**Next:**

- [ANSWER-KEY.md](../ANSWER-KEY.md) compares adoption, `--take-ownership` and delete-and-recreate.
- [LESSON.md](../LESSON.md) covers ownership metadata and server-side apply field managers.
- **breakfix-05: Release Stuck Pending**: every upgrade fails, and nothing else is deploying.
