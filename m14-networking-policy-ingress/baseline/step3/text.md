# Step 3 — Cross-namespace peers

The allow in step 2 reaches across namespaces: a policy in media permits a caller in app-services. The way the peer is written makes that work. A wrong peer allows nothing.

## Read the peer

```bash
kubectl describe networkpolicy allow-broker-from-app -n media
```{{exec}}

Find the From section. It holds one entry: a NamespaceSelector that matches `kubernetes.io/metadata.name=app-services`. Two rules follow:

- A **namespaceSelector** selects the Pods in every namespace whose labels match. This is how a peer crosses a namespace boundary.
- A bare **podSelector** selects Pods in the policy's own namespace. Written alone, this peer would mean "Pods in media" and would never match a caller in app-services.

## Read the label it matches

```bash
kubectl get namespace app-services --show-labels
```{{exec}}

The control plane puts the label kubernetes.io/metadata.name on every namespace. That label is the reliable handle for "namespace X". You do not label namespaces yourself to select them by name.

## The instinct to build

When a cross-namespace call is blocked by an allow that "looks right", read the From entry. Check whether it names a namespace or only a pod.
