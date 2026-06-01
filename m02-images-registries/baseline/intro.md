# M02 — Baseline Tour

Every workload you've met so far started the same way: the kubelet took an image *reference*, asked the container runtime to fetch it, and the runtime pulled it from a registry. M00 and M01 took that step for granted. M02 is about the step itself — turning an image *name* into image *bytes* on a node, and every way that can fail.

This tour runs on the full Polyphone fleet with one workload layered on: **`media-recorder`** (`media`), which pulls a proprietary image from an **in-cluster private registry** running at `localhost:5000` — authenticated with an `imagePullSecret`, the way an internal image really ships. The rest of the fleet still pulls `nginx:1.25` anonymously from Docker Hub.

Four short steps:

1. **Anatomy of an image reference** — `registry/repository:tag@digest`, read off real workloads
2. **Tags move, digests don't** — resolve a tag to its immutable digest and see why pinning matters
3. **imagePullPolicy and the node cache** — when the kubelet pulls vs reuses what's on the node
4. **A healthy private-registry pull** — the registry, the `imagePullSecret`, and a `401` when you skip it

Nothing to fix here. See what healthy image mechanics look like before the break/fix scenarios walk the pull-failure differential. The cluster takes 90–150 seconds to come up — it also stands up the private registry and pushes the proprietary image into it. Click **Start** when ready.
