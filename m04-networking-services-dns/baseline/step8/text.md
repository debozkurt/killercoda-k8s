# Step 8 — A backend is chosen per connection

Service forwarding selects a backend for a new connection, not for each request inside one.

## Give the Service two backends

```bash
kubectl scale deploy/session-broker -n media --replicas=2
kubectl rollout status deploy/session-broker -n media --timeout=90s
```{{exec}}

## Open ten separate connections

```bash
kubectl run probe --rm -i --restart=Never --image=busybox:1.36 -n media -- sh -c \
  'for i in $(seq 1 10); do wget -qO- -T3 http://session-broker/ >/dev/null; done; echo done'
```{{exec}}

## Read what each backend served

```bash
for p in $(kubectl get pods -n media -l app=session-broker -o name); do
  echo "$p served $(kubectl logs -n media "$p" | grep -c 'GET /') request(s)"
done
```{{exec}}

Both Pods served part of the ten. Each `wget` opened its own connection, and each connection was selected independently.

One long-lived connection behaves differently. HTTP keep-alive, WebSockets, HTTP/2, and gRPC reuse a single connection, so the traffic inside it stays on the backend chosen when that connection opened. Scaling out adds backends that an established connection never reaches.

## Put it back

```bash
kubectl scale deploy/session-broker -n media --replicas=1
kubectl rollout status deploy/session-broker -n media --timeout=90s
```{{exec}}
