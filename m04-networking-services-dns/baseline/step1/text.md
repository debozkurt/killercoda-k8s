# Step 1 — A Service is a stable identity

A Service is a stable name and virtual IP in front of a set of Pods whose own IPs change constantly. Learn to reach one — and to see that you never touched a Pod IP — and the rest of the module follows.

## See the Services the fleet runs

```bash
kubectl get svc -A
```{{exec}}

Every plane has them: `session-broker` in `media`, `route-engine` in `call-routing`, `portal-ui` in `admin-portal`, and the headless ones (`CLUSTER-IP: None`) fronting the StatefulSets. Pick one with a normal ClusterIP:

```bash
kubectl get svc session-broker -n media
```{{exec}}

The `CLUSTER-IP` column is a virtual IP (something like `10.96.x.y`), and `PORT(S)` shows `80/TCP`. That IP is stable for the Service's life — no single Pod holds it.

## Reach the Service without knowing a Pod IP

The fleet's nginx Pods don't make calls, so spin up a throwaway client and have it `wget` the Service. `kubectl run --rm` creates a Pod, runs one command, and deletes it:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n media -- \
  wget -qO- --timeout=3 http://session-broker.media/
```{{exec}}

You get nginx's welcome HTML back. The client named the Service — not a Pod — and the request still landed on a running container.

## Confirm the Pods behind it have different IPs

```bash
kubectl get pods -n media -l app=session-broker -o wide
```{{exec}}

The `IP` column shows the Pod's own cluster IP — a different address from the Service's ClusterIP, and one that would change the moment the Pod is replaced. That gap is the entire point of a Service: clients hold the name, the platform churns the Pods. Next, see how the Service knows which Pods to send to.
</content>
