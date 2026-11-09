# Done

The prod overlay disabled the name hash, so the ConfigMap kept one fixed name. The config change updated that ConfigMap in place, the Pod template did not change, and nothing rolled. The containers kept the value they read at start. Restoring the hash made the change roll, and `--prune` removed the leftover ConfigMap.

The reflex: **when the ConfigMap is right and the app is wrong, check whether anything restarted, then check whether the ConfigMap name changed.**

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- With M16 done, M17 contrasts Helm's templates with Kustomize's overlays, and M18 puts a kustomization under Flux.
