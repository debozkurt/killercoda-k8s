# Done

The install failed in the render. The template wraps `config.sipRealm` in `required`, so the render stopped, and Helm wrote nothing to the cluster. The error named the template, the line and the missing value. `helm template` reproduced it without the cluster.

**Next:**

- [ANSWER-KEY.md](../ANSWER-KEY.md) compares `required` with a chart default.
- [LESSON.md](../LESSON.md) covers the render stage and the template type rules.
- **breakfix-04: Ownership Conflict**: an install fails, and this time the chart renders cleanly.
