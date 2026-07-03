# Done

The overlay built fine, and the API server rejected the apply: `spec.selector … field is immutable`. A `commonLabels` transformer was stamping `tier: prod` into *every* selector — harmless on a fresh create, fatal when promoting over a Deployment whose selector already existed. Swapping to the `labels:` transformer with `includeSelectors: false` kept the label on metadata and off the immutable field, and the promotion went through.

The reflex to keep: **when an apply is rejected for an immutable field, diff the live object against the render.** The rejection names the field; the render shows what your overlay tried to put there; the transformer list tells you which mechanism touched it. `commonLabels` (and `labels:` with `includeSelectors: true`) reach into selectors — reserve them for greenfield resources, and prefer `includeSelectors: false` for anything already running. This is the *apply* leaf of the differential: build succeeded, runtime was never reached.

That completes the three-layer differential — **build** (bf-01), **apply** (bf-03), **runtime** (bf-02). Same tool, three very different failure surfaces, three different first commands.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Transformers and the immutable-selector trap.
- With M16 done, M17 (Helm) contrasts templating against Kustomize's overlay model; M18 (Flux) puts a Kustomization under GitOps control.
