# Done

A name failure with a healthy CoreDNS pointed at the pod's own egress. The restrict-egress-to-namespace policy isolated every Pod in media for egress and allowed only media. The DNS query goes to kube-system, so the lookup timed out. The ClusterIP call worked because its backend sat inside the allowed namespace.

The fix added an allow to the CoreDNS Pods on port 53 and kept the lockdown.

The reflex: **an egress policy is as complete as its list of dependencies, and DNS is a dependency of nearly everything.** Test a ClusterIP to split "the network is blocked" from "the name is blocked".

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- For the why, read [`LESSON.md`](../LESSON.md) § Egress and the DNS trap.
- Next scenario: **breakfix-05-ingress-404-pathtype**. The home page loads and a deep link returns 404.
