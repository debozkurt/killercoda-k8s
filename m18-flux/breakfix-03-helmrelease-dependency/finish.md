# Done

You diagnosed a release that was blocked on purpose — not failing to render or install, but waiting on a `dependsOn` that named a Kustomization (`platform-config`) which doesn't exist and never would. Reading the `Ready` condition (`DependencyNotReady`) and confirming the named dependency against `flux get kustomizations` pointed straight at the wrong reference. Correcting it to `apps` let the release install.

**Next:**

- For the canonical path and the dependency-hygiene discussion, see [ANSWER-KEY.md](../ANSWER-KEY.md).
- For the *why* — `dependsOn` ordering and how a HelmRelease sources its chart — read [LESSON.md](../LESSON.md).
- **M18 is complete** (baseline + 3 break/fix). Next on the GitOps track: **M19 Multi-cluster** — promotion across environments and cluster variables.
