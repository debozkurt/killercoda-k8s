# Done

The pipeline was green, and the Secret held the new token. `partner-connector` mounted one key of the Secret volume with `subPath`. The kubelet updates a Secret volume in place but never updates a `subPath` mount, so the file kept the value from container start. Mounting the directory rolled the Pod onto the new token. The second rotation then reached the file with no restart.

The instinct to keep: for a stale file, read the `Mounts:` line in `kubectl describe pod`. A `path=` flag means a `subPath` mount, and that mount behaves like an environment variable for rotation.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Read [`LESSON.md`](../LESSON.md) § Rotation for the table of consumption modes.
- You have broken every link in the pipeline: reference, store read, target write, and both consumer modes.
