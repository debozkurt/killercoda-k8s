# Done

You toured healthy config wiring: ConfigMaps and Secrets as the objects, the two consumption modes — environment variables (frozen at start) and mounted files (live-updating, except `subPath`) — read straight out of running containers, and a Secret decoded to show base64 is encoding, not security. That's the shape of "good"; internalize it so each broken link stands out.

**Next:**

- For the *why* behind all of it, read [`LESSON.md`](../LESSON.md).
- Then work the four break/fix scenarios, in order — together they walk the four ways config breaks a workload:
  - **`breakfix-01-configmap-key-missing`** — `CreateContainerConfigError`: a required env key the ConfigMap doesn't have.
  - **`breakfix-02-secret-volume-missing`** — stuck `ContainerCreating`: a mounted Secret that was never created.
  - **`breakfix-03-stale-env-config`** — config edited, nothing changed: env is frozen and nothing rolled.
  - **`breakfix-04-secret-double-base64`** — `Running` but wrong: a Secret encoded one time too many.
- Check your diagnostic path against [`ANSWER-KEY.md`](../ANSWER-KEY.md) after each.
