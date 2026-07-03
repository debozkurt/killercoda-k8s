# Step 1 — Diagnose the 503

A `503` is the controller saying "I matched a rule but had no healthy backend to send to." So the rule matched — the problem is between the rule and the Service. Prove the backend is fine, then read the rule against it.

## Reproduce the 503 through the controller

```bash
CIP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.clusterIP}')
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -O- --timeout=5 --header "Host: portal.polyphone.example" "http://$CIP/"
```{{exec}}

`wget: server returned error: HTTP/1.1 503 Service Temporarily Unavailable`. The request reached the controller and matched the host rule — a `404` would mean no rule matched — so routing is working; the backend is the question.

## Prove the backend is healthy

```bash
kubectl get endpoints portal-ui -n admin-portal
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 http://portal-ui.admin-portal/
```{{exec}}

`portal-ui` has endpoints on `:80`, and reached directly by its Service it returns nginx's HTML. The Pods, the Service, and the endpoints are all fine. So the controller has a working Service to forward to — but it's answering `503` anyway, which means it isn't finding *that* backend.

## Read the rule against the Service

```bash
kubectl describe ingress portal -n admin-portal
kubectl get svc portal-ui -n admin-portal
```{{exec}}

In the Ingress, the `Backends` / rule shows `portal-ui:8080`. In the Service, `PORT(S)` is `80/TCP` — there is no `8080`. That's the mismatch: the rule forwards to a port the Service doesn't expose, so the controller resolves the backend to *no* endpoints and returns `503`. The Service is healthy on 80; the rule just names the wrong number. On to the fix.
