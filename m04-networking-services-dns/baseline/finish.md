# Done

You walked the in-cluster request path in the order a request takes it: Pod-to-Pod with no Service involved, the network namespace a Pod's interface and route live in (and two containers share), then the Service's stable ClusterIP, the EndpointSlice a selector produces and a controller rebuilds, the `port`/`targetPort`/listener distinction, and DNS resolution from inside a Pod. That is the shape of "healthy" — internalize it so each broken link stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the three break/fix scenarios, in order — together they walk the **connectivity differential** top to bottom, one signature each:
  - **`breakfix-01-dns-cross-namespace`** — `NXDOMAIN`: the name never resolved.
  - **`breakfix-02-selector-mismatch`** — empty EndpointSlice: the Service has no backends.
  - **`breakfix-03-port-mismatch`** — `connection refused`, endpoints populated: the port is wrong.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
