# Done

You toured a healthy mesh:

- Injection added `istio-init` and `istio-proxy` to each `media` pod (2/2), and `istioctl proxy-status` listed every sidecar as `SYNCED`.
- The VirtualService and DestinationRule compiled into an Envoy route and one cluster per subset, and the caller's access log named the cluster for each request.
- `STRICT` mTLS let the meshed caller in and reset the plaintext caller.
- `istioctl proxy-config` showed the empty `canary` cluster, and `istioctl analyze` reported no issue.

**Next:**

- Read [`LESSON.md`](../LESSON.md) for the model behind each step.
- Work the five break/fix scenarios, `breakfix-01` through `breakfix-05`. Each breaks one link of the request path.
- Check each diagnosis against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
