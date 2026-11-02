# Step 2 — Fix it and verify

The backend port in the rule must name a port that the Service exposes. portal-ui exposes 80.

## Correct the backend port

```bash
kubectl patch ingress portal -n admin-portal --type=json \
  -p='[{"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/port/number","value":80}]'
```{{exec}}

The controller reads the change and resolves the backend to portal-ui port 80, which has endpoints.

## Verify

Wait a few seconds first, because the controller reloads its configuration.

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 --header 'Host: portal.polyphone.example' \
  http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/
```{{exec}}

The nginx page returns instead of a 503. Nothing changed on the Service or its Pods. Only the port in the rule changed. Read `finish.md`, then check [`ANSWER-KEY.md`](https://github.com/debozkurt/killercoda-k8s/blob/main/m14-networking-policy-ingress/ANSWER-KEY.md).
