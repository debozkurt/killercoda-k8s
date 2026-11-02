# Step 1 — Diagnose the 503

A 503 means a rule matched and the backend failed. Prove the backend is healthy, then read the rule against it.

## Reproduce the 503

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 --header 'Host: portal.polyphone.example' \
  http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/
```{{exec}}

The call fails with `wget: server returned error: HTTP/1.1 503 Service Temporarily Unavailable`. The request reached the controller and matched the host rule. A 404 would mean no rule matched. Routing works, so the backend is the question.

## Prove the backend is healthy

```bash
kubectl get endpoints portal-ui -n admin-portal
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 http://portal-ui.admin-portal.svc.cluster.local/
```{{exec}}

The Service has endpoints on port 80, and a direct call returns the nginx page. The Pods, the Service and the endpoints are fine.

## Read the rule against the Service

One warning before you read the output: Pod IPs may appear in the parentheses next to portal-ui:8080. Do not read them as proof that the port is valid. kubectl matches endpoints by port name, and this Service's port has no name, so the list appears even though the number is wrong. Compare the numbers yourself.

```bash
kubectl describe ingress portal -n admin-portal
kubectl get svc portal-ui -n admin-portal
```{{exec}}

In the Ingress, the Backends column reads portal-ui:8080. In the Service, PORT(S) reads 80/TCP. No port 8080 exists on the Service.

The rule forwards to a port the Service does not expose. The controller finds no endpoints for it and answers 503. On to the fix.
