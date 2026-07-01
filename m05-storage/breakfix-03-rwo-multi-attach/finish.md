# Done

`directory` had a `Bound` claim and a Pod that still wouldn't start — the third leaf of the differential, and the one that trips people, because `get pvc` looks perfect. A single `ReadWriteOnce` volume was asked to back two replicas on two nodes, and RWO means one node at a time: the second replica hit a `volume node affinity conflict` (the local-volume form of a Multi-Attach error). The fix was to stop spanning nodes — one RWO consumer — with RWX or `volumeClaimTemplates` as the real answer when you genuinely need more.

That completes the storage triage. `get pvc` splits every storage-stuck Pod three ways:

- **`Pending`** → the claim can't bind (break/fix 01 — bad StorageClass).
- **absent** → the Pod names a claim that doesn't exist (break/fix 02).
- **`Bound`, Pod still stuck** → the volume can't attach where the Pod runs (this one — access mode / topology).

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Access modes, attach, and the Multi-Attach failure.
- You've completed M05's break/fix set. Revisit `LESSON.md` § Production thinking, then move on to M06 — Scheduling.
