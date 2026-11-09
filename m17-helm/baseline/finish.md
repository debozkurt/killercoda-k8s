# Done

You walked the Helm pipeline end to end: the chart on disk, the render with `helm template`, the stored manifest with `helm get manifest`, values and an upgrade, the revision history and a rollback. Then a hand edit made the next upgrade fail with a field conflict, and `--force-conflicts` gave the field back to Helm.

**Next:**

- [LESSON.md](../LESSON.md) explains the render, record and apply stages, values precedence, the release record and ownership.
- Five break/fix scenarios follow, one per failure stage. Start with **breakfix-01: Values Key Ignored**.

After each scenario, check yourself against [ANSWER-KEY.md](../ANSWER-KEY.md).
