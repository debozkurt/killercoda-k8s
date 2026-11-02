# Step 1 — The policies in media

A **NetworkPolicy** is a namespaced list of allowed pod traffic. A pod is open for a direction until a policy selects it for that direction. After that, the pod accepts only what the policies list. The media namespace has two policies.

## Read the default-deny

```bash
kubectl get networkpolicy -n media
kubectl describe networkpolicy default-deny-ingress -n media
```{{exec}}

The PodSelector line reads `<none> (Allowing the specific traffic to all pods in this namespace)`. An empty selector selects every Pod in media. The ingress section reads `<none> (Selected pods are isolated for ingress connectivity)`. The policy lists no allowed sources, so every Pod in media is isolated for ingress. This is a default-deny.

## Read the allow

```bash
kubectl describe networkpolicy allow-broker-from-app -n media
```{{exec}}

This policy selects only the Pods with the label app=session-broker. It allows TCP port 80 from the app-services namespace. Policies are additive. The result is: session-broker accepts port 80 from app-services, and everything else in media is denied. No deny rule exists. Isolation comes from the absence of an allow.

## The instinct to build

Build policy in two moves: deny broadly, then allow narrowly. Next, test that the cluster enforces it.
