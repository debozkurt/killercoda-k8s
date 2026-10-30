# Done

Three Pods ran with the right names, and none resolved by name. The StatefulSet named `session-store` as its governing Service in `serviceName`, and nobody created that Service. Cluster DNS publishes no per-Pod record without a headless Service behind the name. One Service with `clusterIP: None` and a selector for the Pods fixed it.

A StatefulSet has three guarantees. This failure broke one and left two intact, so `Running` told you nothing. Check the guarantee itself: resolve the name.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § The StatefulSet's three guarantees.
- Next scenario: **`breakfix-02-ordered-rollout-stall`**. The Pods are not all there this time. One un-Ready Pod holds back the rest.
