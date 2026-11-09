# Done

The prod overlay set `tier: prod` with `commonLabels`, which writes into every selector. The Deployment's selector is immutable, so the API server rejected the promotion over the running lab Deployment. The Service update in the same apply succeeded, and its new selector matched no Pod. The `labels:` transformer with `includeSelectors: false` kept the label on metadata, and the promotion became an ordinary update.

The reflex: **when an apply fails with `field is immutable`, compare the live field with the render, then find the transformer that wrote it.**

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Next scenario: **`breakfix-04-patch-matches-nothing`**.
