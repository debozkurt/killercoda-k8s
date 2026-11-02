# Step 2 — Enforcement, proven both ways

The API server stores a NetworkPolicy whether or not anything acts on it. The network plugin (the CNI) enforces it. Prove enforcement with a source the policy allows and a source it does not.

## The allowed path

The allow policy permits TCP port 80 to session-broker from app-services. Call it from a throwaway client in that namespace:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/
```{{exec}}

nginx returns its welcome page.

## The denied path

Make the same call from signaling. No policy allows that namespace:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n signaling -- \
  wget -qO- --timeout=5 http://session-broker.media.svc.cluster.local/
```{{exec}}

The call hangs, then fails with `wget: download timed out`. Nothing refused the connection. The CNI dropped the packet, so the client waits. M04's loud failures are different: NXDOMAIN and connection refused return at once.

## The instinct to build

The Service, the name and the endpoints are identical in both calls. The caller's namespace decides the result. A timeout with a healthy Service now reads as "a policy is dropping this".
