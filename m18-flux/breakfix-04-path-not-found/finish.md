# Done

The build stage stopped. The source fetched the restructure commit, and the `apps` Kustomization tried to build `./apps` from it. That directory had moved to `./deploy/apps`, so the build failed with `kustomization path not found`. A failed build applies nothing and prunes nothing, so the objects from the last good build kept running. Pointing `spec.path` at the new directory let the commit apply.

**Next:**

- [ANSWER-KEY.md](../ANSWER-KEY.md) covers why the `Kustomization` itself belongs in git, and the CI check that catches a moved path.
- [LESSON.md](../LESSON.md) covers the four steps of a pass.
- **breakfix-05: Health Check, Fix in Git** — a commit applies, its Pods never become ready, and Flux undoes every hand fix.
