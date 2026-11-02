# Step 4 — A Pod's security posture: securityContext

RBAC controls what a Pod's process may ask the API server. The **securityContext** controls how the container runs on the node: its user, its privileges, and its Linux capabilities.

## What does the fleet set?

The Pod YAML is long, so search it for the field:

```bash
kubectl get pod -n media -l app=session-broker -o yaml | grep securityContext
```{{exec}}

One line: `securityContext: {}`. That is the Pod-level block, and it is empty. The container has no block at all. The fleet runs with the runtime defaults.

## Confirm the user

```bash
kubectl exec -n media deploy/session-broker -- id -u
```{{exec}}

The output is 0. The process runs as root, because the image declares no other user and nothing overrides it.

## The fields that harden a Pod

| Field | Effect |
|-------|--------|
| `runAsNonRoot: true` | The kubelet refuses to start a container whose user is root |
| `runAsUser: 1000` | Runs the process as that UID |
| `allowPrivilegeEscalation: false` | A child process cannot gain privileges (setuid) |
| `capabilities: { drop: ["ALL"] }` | Removes every Linux capability |
| `seccompProfile: { type: RuntimeDefault }` | Applies the runtime's default syscall filter |

`runAsNonRoot` only checks the user. It does not change it. For an image that runs as root, you also need `runAsUser`.

These five fields are the core of the `restricted` Pod Security Standard. Step 5 makes a namespace require them.
