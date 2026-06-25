# Done

You walked the in-cluster request path end to end: a Service's stable ClusterIP reached without ever touching a Pod IP, the EndpointSlice that a selector populates (and the `get endpoints` check that proves a Service has somewhere to send traffic), the `port`/`targetPort`/`containerPort` distinction where only the listener matters, and DNS resolution from inside a Pod — short name, `<svc>.<ns>`, and FQDN. That's the shape of "healthy" — internalize it so each broken link stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order — together they walk the **connectivity differential** top to bottom, one signature each:
  - **`breakfix-01-dns-cross-namespace`** — `NXDOMAIN`: the name never resolved.
  - **`breakfix-02-selector-mismatch`** — empty EndpointSlice: the Service has no backends.
  - **`breakfix-03-port-mismatch`** — `connection refused`, endpoints populated: the port is wrong.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
</content>
