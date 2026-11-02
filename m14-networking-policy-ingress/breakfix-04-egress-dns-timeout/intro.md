# M14 — Break/fix 04: egress policy breaks DNS

> Pre-req: the M14 baseline tour and break/fix 01. You know the ingress signature. This scenario isolates a namespace for egress.

After a security hardening, workloads in the media namespace report name failures. Lookups for session-broker and every other Service fail. CoreDNS looks healthy, and other namespaces resolve names normally. The failure feels like a DNS outage.

Someone applied a policy that lets media Pods send traffic only to other Pods in media. That rule sounds complete. It leaves out the packet that every application sends first: the DNS query to CoreDNS in kube-system.

Your job: show that DNS itself is healthy, show that the network path works by IP, find the policy, and add the allow that the lockdown is missing. Keep the lockdown.

The cluster takes 60–120 seconds to start. Click **Start** when ready.
