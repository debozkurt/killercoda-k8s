# Done

The caller's access log read `503 UH` and named the `canary` cluster. The VirtualService routed to `canary`, the DestinationRule defined it as `version: canary`, and no pod carried that label. `istioctl proxy-config endpoints` showed the cluster empty. Routing back to `stable` restored the calls.

The reflex: **a mesh 503 with healthy pods is a configuration problem. Read the caller's access log first; the cluster name tells you where the route went.** `istioctl analyze` does not report a subset that selects zero pods, and the VirtualService applies without error.

**Next:**

- Check your path against [`ANSWER-KEY.md`](../ANSWER-KEY.md).
- Next scenario: **`breakfix-03-mtls-mode-mismatch`**.
