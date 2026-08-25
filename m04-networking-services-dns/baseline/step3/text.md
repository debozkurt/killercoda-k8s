# Step 3 — port, targetPort, containerPort

Three port fields show up around a Service, and conflating them is a classic source of "the endpoints are right but it still won't connect." Only one of the three actually opens a socket.

## Read the Service's two ports

```bash
kubectl get svc session-broker -n media -o yaml | grep -A3 'ports:'
```{{exec}}

You'll see `port: 80` and `targetPort: 80`:

- **`port`** is what clients connect to — `session-broker:80`.
- **`targetPort`** is the Pod port the Service forwards to. Omit it and it defaults to `port`.

The EndpointSlice records the resolved target port — confirm it lands on the Pod's `:80`:

```bash
kubectl get endpoints session-broker -n media
```{{exec}}

Each entry reads `PodIP:80`. That's `targetPort` made concrete.

## The third field opens nothing

The Pod spec also declares a `containerPort`:

```bash
kubectl get pods -n media -l app=session-broker \
  -o jsonpath='{.items[0].spec.containers[0].ports}'; echo
```{{exec}}

`containerPort: 80` is **documentation**. It advertises intent; it does not open or close a socket. The process inside listens on whatever it listens on — nginx serves `:80` whether or not `containerPort` says so. The field that decides where traffic is *delivered* is `targetPort`; the field that decides whether anything *answers* there is the process. When those two disagree, you get a refused connection with perfect-looking endpoints (the third break/fix scenario).

## Reach a Service port locally with port-forward

`kubectl port-forward` tunnels a local port to a Service (or Pod) — the standard way to poke an in-cluster Service from your workstation:

```bash
kubectl port-forward svc/session-broker 8080:80 -n media >/tmp/pf.log 2>&1 &
PF=$!; sleep 2
curl -s http://localhost:8080/ | head -1
kill $PF 2>/dev/null
```{{exec}}

The `curl` to `localhost:8080` returns nginx's first HTML line — forwarded through the Service to a backend Pod's `:80`. Next, reach the same Service the way every Pod really does: by name, through cluster DNS.
