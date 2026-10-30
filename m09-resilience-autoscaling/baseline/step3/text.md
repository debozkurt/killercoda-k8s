# Step 3 — Push the HPA past its target

An HPA that has never scaled is unproven. Generate load and watch it act.

## Expose a port nginx serves

The fleet Service for `sip-router` maps port 5060, where nginx does not listen. Expose port 80 for this step:

```bash
kubectl expose deployment sip-router -n signaling --name=sip-router-load --port=80 --target-port=80
```{{exec}}

## Start the load

A **Pod** is the smallest unit Kubernetes runs. This one loops HTTP requests at the Service:

```bash
kubectl run load -n signaling --image=busybox:1.36 --restart=Never -- \
  /bin/sh -c "while true; do wget -q -O- http://sip-router-load > /dev/null; done"
```{{exec}}

## Watch the HPA react

```bash
kubectl get hpa sip-router -n signaling -w --request-timeout=120s
```{{exec}}

Within about a minute `TARGETS` climbs above 50% and `REPLICAS` rises from 2 toward 6. Stop the watch with Ctrl-C when `REPLICAS` has risen. Then read the decision:

```bash
kubectl describe hpa sip-router -n signaling
```{{exec}}

The `Events:` block shows SuccessfulRescale with a new size and the reason: cpu resource utilization (percentage of request) above target.

## Remove the load

```bash
kubectl delete pod load -n signaling --now
kubectl delete service sip-router-load -n signaling
```{{exec}}

`REPLICAS` stays high. Scale-down waits out a 5-minute stabilization window, and scale-up has none. Do not wait for it. Next: protect Pods during a disruption.
