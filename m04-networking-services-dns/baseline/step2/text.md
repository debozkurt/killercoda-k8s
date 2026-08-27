# Step 2 — A Service is a stable identity

A Service is a stable name and virtual IP in front of a set of Pods whose own IPs change constantly. Learn to reach one — and to see that you never touched a Pod IP — and the rest of the module follows.

## See the Services the fleet runs

```bash
kubectl get svc -A
```{{exec}}

Every plane has them: `session-broker` in `media`, `route-engine` in `call-routing`, `portal-ui` in `admin-portal`, and the headless ones fronting the StatefulSets, which read `None` in the `CLUSTER-IP` column. Pick one with a normal ClusterIP:

```bash
kubectl get svc session-broker -n media
```{{exec}}

Two columns carry the lesson. `CLUSTER-IP` holds a virtual address out of the Service range, 10.96.0.0/12 on this cluster — stable for the Service's life, and held by no single Pod. `PORT(S)` reads 80/TCP: the port clients connect to.

## Reach the Service without knowing a Pod IP

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- -T3 http://session-broker/ | head -4
```{{exec}}

You get nginx's welcome HTML back. The client named the Service — not a Pod — and the request still landed on a running container.

## Confirm the Pods behind it have different IPs

```bash
kubectl get pods -n media -l app=session-broker -o wide
```{{exec}}

The `IP` column shows the Pod's own address, different from the Service's ClusterIP and gone the moment the Pod is replaced. That gap is the entire point of a Service: clients hold the name, the platform churns the Pods. Next, see how the Service knows which Pods to send to.
