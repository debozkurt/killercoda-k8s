# Done

Two consumers in two namespaces failed for one reason. The RoleBinding that grants store access named `secret-operator-ro`, a ServiceAccount that does not exist. The operator, running as `secret-operator`, could not read the store, so it set every sync to `StoreNotReady` and wrote nothing. One subject fix restored the whole pipeline on the next pass.

The instinct to keep: a failure on every sync that names one store is one problem at the store. Prove the controller's identity with `kubectl auth can-i ... --as=system:serviceaccount:<ns>:<name>` before you open any single sync.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Read [`LESSON.md`](../LESSON.md) § the store's own identity (the deep dive).
- Continue to `breakfix-03-rotation-not-propagated`.
