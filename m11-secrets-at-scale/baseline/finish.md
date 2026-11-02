# Done

You read a healthy secrets pipeline from end to end:

- The `SecretSync` objects name store keys and hold no values.
- The operator wrote a derived Secret for each one and reported `Synced` in `.status`.
- The consumer's environment holds the store's value.
- A hand edit to the derived Secret lasted one reconcile pass.
- etcd holds the Secret in clear text, because the API server has no encryption config.

The rule to carry forward: a derived Secret has its failure story in the object that produces it. Read that object's `.status` before the consumer's logs.

**Next:**

- Read [`LESSON.md`](../LESSON.md) for the model behind the pipeline.
- Work the break/fix scenarios. 01, 02 and 04 each break one link before the Secret exists (reference, store read, target write). 03 and 05 break the last link, after a rotation (env and `subPath`).
- Check each path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
