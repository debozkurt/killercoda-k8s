# Step 2 — Fix it and verify

Prefix matches by path element. A rule with Prefix and path / matches every path under /. Change pathType to Prefix.

## Correct the pathType

```bash
kubectl patch ingress portal -n admin-portal --type=json \
  -p='[{"op":"replace","path":"/spec/rules/0/http/paths/0/pathType","value":"Prefix"}]'
```{{exec}}

The controller reloads its configuration within a few seconds.

## Verify

Wait a few seconds first, because the controller reloads its configuration.

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 --header 'Host: portal.polyphone.example' \
  http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/index.html
```{{exec}}

The nginx page returns. The Service, the Pods and the host did not change. Only the match rule changed. Read `finish.md`, then check [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m14-networking-policy-ingress/ANSWER-KEY.md).
