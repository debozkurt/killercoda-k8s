# Step 2 — Fix it and verify

A cluster-scoped resource needs a **ClusterRole** granted by a **ClusterRoleBinding**.

## Grant it cluster-wide

```bash
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding node-inspector \
  --clusterrole=node-reader --serviceaccount=analytics:node-inspector
kubectl auth can-i list nodes --as=system:serviceaccount:analytics:node-inspector
```{{exec}}

The answer is yes. The ClusterRoleBinding names the ServiceAccount as its subject and grants across the cluster.

## Remove the inert grant

The namespaced Role and RoleBinding grant nothing. Delete both. With two kinds in one command, use the kind/name form. Otherwise kubectl reads the second word as another Role name:

```bash
kubectl delete role/node-reader rolebinding/node-inspector-binding -n analytics
```{{exec}}

## Clear the backoff and verify

```bash
kubectl rollout restart deployment node-inspector -n analytics
kubectl rollout status deployment node-inspector -n analytics --timeout=60s
kubectl logs -n analytics deploy/node-inspector --tail=2
```{{exec}}

The log shows HTTP 200. The scope was wrong, and the verb and identity were correct. For self-grading, see [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m10-security-rbac/ANSWER-KEY.md).
