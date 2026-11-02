# Step 4 — The Ingress front door

A ClusterIP Service is reachable only inside the cluster. An **Ingress** routes outside HTTP to a Service by hostname and path. The object does nothing alone. A **controller** must claim it and proxy the requests.

## Find the controller and its class

```bash
kubectl get pods -n ingress-nginx
kubectl get ingressclass
```{{exec}}

The controller Pod is the proxy. The IngressClass named nginx is its name. An Ingress picks a controller by setting ingressClassName to a class that the controller owns.

## Read the Ingress

```bash
kubectl get ingress -n admin-portal
kubectl describe ingress portal -n admin-portal
```{{exec}}

The CLASS column reads nginx, so the controller claimed the Ingress. The ADDRESS column holds the controller's address. An Ingress that no controller claims shows no ADDRESS. The Rules section routes the host portal.polyphone.example, path /, to portal-ui on port 80. The Events section shows the controller syncing the object.

## Route a request

Call the controller with the Host header that the rule names:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 --header 'Host: portal.polyphone.example' \
  http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/
```{{exec}}

portal-ui's nginx page comes back. The controller matched the host and path, then forwarded to the Service.

## Miss the rule

Change the Host header to a host that no rule names:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 --header 'Host: unknown.polyphone.example' \
  http://ingress-nginx-controller.ingress-nginx.svc.cluster.local/
```{{exec}}

The controller answers `404 Not Found`. No rule matched, so no backend was tried. A 404 means a rule problem. A 503 means a backend problem. The break/fix scenarios use both.
