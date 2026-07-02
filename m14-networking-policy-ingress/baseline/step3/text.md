# Step 3 — Cross-namespace peer selection

The allow in step 2 reached *across* namespaces — a policy in `media` permitting a source in `app-services`. That only works because of how the peer is written. Get this wrong and a policy that looks right allows nothing.

## Read the `from` peer

```bash
kubectl get networkpolicy allow-broker-from-app -n media -o yaml | grep -A6 ingress:
```{{exec}}

The `from` peer is a `namespaceSelector` matching `kubernetes.io/metadata.name: app-services`. Two things matter here:

- **`namespaceSelector` reaches across namespaces.** A bare `podSelector` under `from` would mean "pods in `media`" — the policy's *own* namespace — and would never match a caller in `app-services`. Cross-namespace allow always needs a `namespaceSelector`.
- **Namespaces are selected by label, not by name string.** The selector matches namespace *labels*, so the namespace has to carry one.

## See the label the selector matches

```bash
kubectl get namespace app-services --show-labels
```{{exec}}

Every namespace automatically carries `kubernetes.io/metadata.name=<its-name>`, applied by the control plane. That is the reliable handle for "namespace X" in a `namespaceSelector` — you don't have to label namespaces yourself to reference them by name.

## The instinct to build

`podSelector` is namespace-local; `namespaceSelector` is how you cross the boundary. When a cross-namespace call is blocked despite an allow that "looks correct," the first thing to check is whether the `from` peer names the *namespace* at all — or only a pod, which silently stays inside the policy's own namespace.
