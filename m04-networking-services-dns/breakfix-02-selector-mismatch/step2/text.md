# Step 2 — Fix it and verify

The Pods are healthy and correctly labeled `app=route-engine`; the Service's selector drifted to `app: route-enginev2`. Point the selector back at the label the Pods actually carry.

## Correct the selector

```bash
kubectl patch svc route-engine -n call-routing \
  -p '{"spec":{"selector":{"app":"route-engine"}}}'
```{{exec}}

The endpoints controller re-evaluates immediately: with the selector matching the Pods again, it writes their addresses into the EndpointSlice.

Or by hand:

```bash
kubectl edit svc route-engine -n call-routing
# change  selector.app: route-enginev2
# to      selector.app: route-engine   (the label the Pods carry)
```

(The mirror-image fix is valid too — if the *Pods'* label was the thing that drifted, you'd correct the Deployment's `template.metadata.labels` instead. Fix whichever side is wrong; here it's the Service.)

## Verify

```bash
kubectl get endpoints route-engine -n call-routing
kubectl run net-test --rm -i --restart=Never --image=busybox:1.36 -n call-routing -- \
  wget -qO- --timeout=3 http://route-engine/
```{{exec}}

`ENDPOINTS` now lists the Pod IPs on `:80`, and the `wget` returns nginx's HTML — the Service has backends again. The Pods never changed; only the selector did. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
</content>
