# Step 5 — port, targetPort, and the listener

Three port fields show up around a Service, and conflating them is a classic source of "the endpoints are right but it still won't connect." Only one of the three actually opens a socket.

## Read the Service's two ports

```bash
kubectl describe svc session-broker -n media
```{{exec}}

`Port: 80/TCP` and `TargetPort: 80/TCP`, two lines apart:

- **`port`** is what clients connect to — `session-broker:80`.
- **`targetPort`** is the Pod port the Service forwards to. Omit it and it defaults to `port`.

The `Endpoints:` line right below shows the same thing made concrete: each backend is listed as PodIP:80. That is `targetPort` resolved.

## The third field opens nothing

The Pod spec also declares a `containerPort`:

```bash
kubectl describe pod -n media -l app=session-broker
```{{exec}}

In the container block, `Port: 80/TCP` is that declaration. It is **documentation**. It advertises intent; it does not open or close a socket. The process inside listens on whatever it listens on — nginx serves :80 whether or not `containerPort` says so.

The field that decides where traffic is *delivered* is `targetPort`. The field that decides whether anything *answers* there is the process. When those two disagree you get a refused connection with perfect-looking endpoints.

## Reach a Service port locally with port-forward

`kubectl port-forward` tunnels a local port to a Service or Pod — the standard way to poke an in-cluster Service from your own machine:

```bash
kubectl port-forward svc/session-broker 8080:80 -n media &
PF=$!
sleep 2
curl -s http://localhost:8080/ | head -4
kill $PF
```{{exec}}

The `curl` to `localhost:8080` returns nginx's HTML, forwarded to a backend Pod's :80. Note what it did *not* use: no ClusterIP, no cluster DNS. It reaches the Pod through the apiserver, which is what makes it a precise probe — it proves the process is listening without proving anything about the Service.
