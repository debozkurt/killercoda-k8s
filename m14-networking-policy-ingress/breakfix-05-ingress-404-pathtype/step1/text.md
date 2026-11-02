# Step 1 — Diagnose the 404

A 404 can come from the controller (no rule matched) or from the backend (the app has no such path). Tell them apart before you change anything.

## Compare the two paths

The home page works through the Ingress:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 --header 'Host: portal.polyphone.example' \
  http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/
```{{exec}}

The nginx page returns. Now request the deep link /index.html:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 --header 'Host: portal.polyphone.example' \
  http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/index.html
```{{exec}}

The call fails with `wget: server returned error: HTTP/1.1 404 Not Found`.

## Ask the backend directly

Call the same path on the Service and skip the Ingress:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 http://portal-ui.admin-portal.svc.cluster.local/index.html
```{{exec}}

The backend serves the page. The same path works directly and fails through the Ingress, so the app is fine. The 404 comes from the controller: no rule matched.

## Read the controller's log

```bash
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller --tail=30 | grep index.html
```{{exec}}

Each access line holds a bracketed upstream name. The 404 line names upstream-default-backend. No rule handled the request, so the controller used its default backend. A request that a rule handled names the namespace, Service and port instead.

## Read the rule

```bash
kubectl get ingress portal -n admin-portal -o yaml
```{{exec}}

Find the paths entry. The host matches the request. The path is /, and pathType reads Exact. Exact matches the whole URL path and nothing else, so only / matches. A request for /index.html matches no rule. On to the fix.
