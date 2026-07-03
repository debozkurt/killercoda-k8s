# Step 2 — Enforcement, proven both ways

A policy is only real if the network plugin (the CNI) enforces it. The API server stores a NetworkPolicy whether or not anything acts on it — so prove enforcement by connecting from a source the policy allows, and one it doesn't.

## The allowed path: from app-services

`allow-broker-from-app` permits TCP:80 to `session-broker` from the `app-services` namespace. Spin up a throwaway client there and connect:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n app-services -- \
  wget -qO- --timeout=5 http://session-broker.media/
```{{exec}}

You get nginx's welcome HTML. The policy allows this source, so the connection completes.

## The denied path: from signaling

Now the same request from `signaling`, which no policy allows:

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n signaling -- \
  wget -qO- --timeout=5 http://session-broker.media/
```{{exec}}

This **hangs**, then fails with `wget: download timed out`. That is the NetworkPolicy signature: the packet is silently dropped, no connection refused comes back, the client just waits. Compare it to M04 — `NXDOMAIN` (name didn't resolve) and `connection refused` (a pod actively rejected) are loud and immediate; a policy drop is a quiet timeout.

## The instinct to build

Same Service, same DNS name, same populated endpoints — two different outcomes decided entirely by *where the caller sits*. The allowed source gets nginx; the denied source gets a timeout. Enforcement is real, and a hang-to-timeout with everything else healthy now reads as "a policy is dropping this."
