# Step 2 — Fix it and verify

A cluster-scoped resource can only be granted by a **ClusterRole** through a **ClusterRoleBinding**. Re-grant `list nodes` that way.

## Create a ClusterRole and bind it cluster-wide

```bash
kubectl create clusterrole node-reader \
  --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding node-inspector \
  --clusterrole=node-reader \
  --serviceaccount=analytics:node-inspector
```{{exec}}

The `--serviceaccount=analytics:node-inspector` flag adds the SA as the binding's subject. Unlike the namespaced RoleBinding, a ClusterRoleBinding grants across the whole cluster — which is what a cluster-scoped resource requires.

The old namespaced Role and RoleBinding are inert (they grant nothing), so you can leave them or tidy up:

```bash
kubectl delete role node-reader rolebinding node-inspector-binding -n analytics
```{{exec}}

## Verify the decision

```bash
kubectl auth can-i list nodes \
  --as=system:serviceaccount:analytics:node-inspector
```{{exec}}

`yes` — note there's no `-n`, because the question is cluster-scoped now. Clear the CrashLoop backoff and confirm the reader gets through:

```bash
kubectl rollout restart deployment node-inspector -n analytics
kubectl rollout status deployment node-inspector -n analytics --timeout=60s
kubectl logs -n analytics deploy/node-inspector --tail=4
```{{exec}}

`Running`, and the logs show `HTTP 200` with the node list. The verb and the identity were never the problem — the *scope* was. For self-grading and the full `Forbidden` differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
