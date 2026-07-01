# Step 3 — A Pod's security posture: securityContext

RBAC governs what a Pod's process may *ask the API*. The **securityContext** governs what the Pod itself may *be* on the node — user, privileges, capabilities.

## What does the fleet run with?

```bash
kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{.items[0].spec.securityContext}'; echo
kubectl get pod -n media -l app=session-broker \
  -o jsonpath='{.items[0].spec.containers[0].securityContext}'; echo
```{{exec}}

Both empty. The fleet runs with the permissive defaults — root user, all default Linux capabilities, privilege escalation allowed. Fine in a lab; a liability in a shared cluster.

## Confirm it's actually root

```bash
kubectl exec -n media deploy/session-broker -- id -u
```{{exec}}

`0` — UID 0, root inside the container. Nothing here stops it.

## The fields that tighten it

A hardened Pod sets these (you'll write exactly this set in break/fix 04):

- `runAsNonRoot: true` — kubelet refuses to start a container that would run as root
- `runAsUser: 1000` — pin a non-root UID
- `allowPrivilegeEscalation: false` — block setuid escalation
- `capabilities: { drop: ["ALL"] }` — start from zero capabilities
- `seccompProfile: { type: RuntimeDefault }` — apply the runtime's default syscall filter

Setting these by hand on every workload is error-prone — so Kubernetes bundles them into named **Pod Security Standards** and enforces them per namespace. That's the last gate, next.
