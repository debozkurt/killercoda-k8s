# Done

You walked the delivery loop in order. The `GitRepository` fetched a commit and stored it as an artifact with a revision. The `apps` Kustomization built `./apps`, applied it, waited for health and recorded an inventory. It reverted a hand scale on the next pass, and the HelmRelease kept one. A push moved every revision forward, and deleting a file pruned its object.

**Next:**

- [LESSON.md](../LESSON.md) covers the four stages and why a failure leaves the later stages on the last good result.
- **breakfix-01** to **breakfix-05** each stop one stage. Read the Flux objects in pipeline order, and compare revisions.
- Check yourself against [ANSWER-KEY.md](../ANSWER-KEY.md) after each scenario.
