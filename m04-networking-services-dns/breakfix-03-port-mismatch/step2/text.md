# Step 2 — Fix it and verify

The selector and endpoints are correct; only the `targetPort` is wrong — it forwards to 8080, but nginx listens on 80. Point it at the real listener.

## Correct the targetPort

```bash
kubectl patch svc portal-ui -n admin-portal \
  -p '{"spec":{"ports":[{"port":80,"targetPort":80}]}}'
```{{exec}}

kube-proxy reprograms the rules, and the EndpointSlice now records the backends on `:80`.

Or by hand:

```bash
kubectl edit svc portal-ui -n admin-portal
# change  targetPort: 8080
# to      targetPort: 80   (where the process actually listens)
```

## Why named ports prevent this

The durable fix for this whole class of bug is a **named port**: declare `ports: [{name: http, containerPort: 80}]` on the container and set the Service's `targetPort: http`. The Service then references the port *by name*, the number lives in exactly one place, and a Service and a container can't drift to different numbers. A readiness probe on the real port helps too — it would have failed these Pods out of the EndpointSlice, turning a silent refused-with-endpoints into a visible not-`Ready` Pod.

## Verify

```bash
kubectl get endpoints portal-ui -n admin-portal
kubectl run net-test --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=3 http://portal-ui/
```{{exec}}

`ENDPOINTS` now shows the Pod IPs on `:80`, and the `wget` returns nginx's HTML — traffic is delivered to a port with a listener. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
</content>
