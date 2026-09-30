# Done

The symptom matched breakfix-01, a `Pending` Pod, but the event named a different filter: `untolerated taint {dedicated: telephony}`. The node was not short of anything. Its taint repels every Pod that does not opt in, and `pstn-probe` had not opted in. One toleration with the taint's key, value and effect fixed it.

Two facts to keep. **Taints live on the node**, so `describe node` is where you read them. **`NoSchedule` does not evict**: the running fleet stayed on the tainted node, and only new placement stopped.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the *why*, see [`LESSON.md`](../LESSON.md) § Taints and tolerations.
- Next scenario: **`breakfix-03-antiaffinity-unschedulable`**. The resources fit and no taint blocks the Pods, yet two replicas still do not schedule.
