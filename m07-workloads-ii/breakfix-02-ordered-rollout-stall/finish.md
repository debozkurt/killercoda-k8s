# Done

`READY 0/3` looked like most of the set had failed. Nothing had failed to deploy. `session-store-0` ran with a readiness probe on port 8080 while the container served port 80, so it never became Ready. Under `OrderedReady`, the controller does not create ordinal `N+1` until ordinal `N` is Running and Ready. One un-Ready Pod accounted for the two missing ones.

The second lesson: patching the template did not change the broken Pod. The controller waits on an un-Ready Pod before it does anything else, including repairing that Pod. The repair is the corrected template plus a manual delete.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Ordered lifecycle.
- Next scenario: **`breakfix-03-daemonset-node-coverage`**. Move from StatefulSets to DaemonSets, and a node-local agent that runs on fewer nodes than you have.
