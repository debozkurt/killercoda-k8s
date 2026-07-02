# Step 4 — The Ingress front door

A ClusterIP Service is reachable only inside the cluster. **Ingress** is the L7 front door that accepts external HTTP and routes it, by hostname and path, to a Service. But an Ingress object does nothing on its own — a *controller* has to claim it and do the proxying.

## See the controller that does the work

```bash
kubectl get pods -n ingress-nginx
kubectl get ingressclass
```{{exec}}

The `ingress-nginx-controller` pod is the proxy; the `nginx` IngressClass is its name. An Ingress selects a controller by setting `ingressClassName` to a class the controller owns.

## See the Ingress object

```bash
kubectl get ingress -n admin-portal
kubectl describe ingress portal -n admin-portal
```{{exec}}

The `portal` Ingress routes host `portal.polyphone.example`, path `/`, to the `portal-ui` Service on port 80. Note the `CLASS` is `nginx` — that is what let the controller claim it. The `Backends` line shows the Service's endpoints the controller will forward to.

## Route a request through it

The controller listens on port 80 of its Service. Send an HTTP request with the matching `Host` header from a throwaway client:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 --header 'Host: portal.polyphone.example' \
  http://ingress-nginx-controller.ingress-nginx/
```{{exec}}

You get `portal-ui`'s nginx HTML — the controller matched the host to the rule and forwarded to the backend Service. Change the `Host` header to something with no rule and you'd get a `404`; point the rule at a Service with no endpoints and you'd get a `503`. Those two codes are the whole Ingress differential, and the next scenarios turn on them.
