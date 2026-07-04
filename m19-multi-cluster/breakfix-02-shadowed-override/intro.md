# M19 — Break/fix 02: Shadowed Override

> Pre-req: break/fix 01. There, a value was wrong because its owning layer was stale. Here the owning layer is *correct* — and the value is still wrong.

Capacity planning raised the `us-east-1` session-capacity standard from 5000 to 8000, committed the change to the region overlay, and moved on. Every `us-east-1` cluster should now render `MAX_SESSIONS=8000`. `prod-us-east-1` still renders `5000`. The region file plainly says `8000` — you can read it — yet the render disagrees with it.

This is the mirror image of the last scenario. The layer that *owns* the value is right. A *different* layer, later in the composition stack, is overriding it — and later layers win. The edit you'd naturally make (fix the region overlay) is already done; the file that's actually wrong is somewhere else in the path.

The fleet repo is at `/root/fleet`. The `prod-us-east-1` cluster is applied into the `edge` namespace, running on the shadowed value. The cluster takes 60–120 seconds to come up. Click **Start** when ready.
