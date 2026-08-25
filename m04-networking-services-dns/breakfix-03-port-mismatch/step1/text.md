# Step 1 — Diagnose: refused, with endpoints

After breakfix-02 your first move is `get endpointslice`. The twist here: they're populated, and the connection still fails. That combination is its own diagnosis.

## Confirm the symptom

```bash
kubectl run net-test --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=3 http://portal-ui/
```{{exec}}

`Connection refused`. Refused is different from dropped: the packet reached a Pod and was actively rejected, rather than vanishing into a Service with no backends.

## Check endpoints — this is NOT the black hole

```bash
kubectl get endpointslice -n admin-portal \
  -l kubernetes.io/service-name=portal-ui
```{{exec}}

The slice lists Pod addresses — and look at the **port** beside them: `:8080`. The selector matched, the Pods are Ready, the EndpointSlice is full. So this isn't breakfix-02. Populated endpoints + refused connection = a *port* problem.

## Find the port the Service forwards to

```bash
kubectl get svc portal-ui -n admin-portal -o yaml | grep -A3 'ports:'
```{{exec}}

`port: 80`, `targetPort: 8080`. The Service accepts traffic on 80 and forwards it to the Pod's `8080`. Now check what the container actually listens on — nginx serves `:80`. Prove it by hitting a Pod directly on 80:

```bash
POD_IP=$(kubectl get pod -n admin-portal -l app=portal-ui -o jsonpath='{.items[0].status.podIP}')
kubectl run net-test --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  sh -c "wget -qO- --timeout=3 http://$POD_IP:80/ | head -1"
```{{exec}}

The Pod answers on `:80` — so the listener is on 80, but the Service forwards to 8080, where nothing is bound. (The Pod's `containerPort: 80` is just documentation; it never opened 8080.) The Service is delivering traffic to a dead port. On to the fix.
