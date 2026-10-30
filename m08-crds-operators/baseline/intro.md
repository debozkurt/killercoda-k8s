# M08 — Baseline Tour

Every type you have used so far is built in: Pods, Deployments, Services. The API server also accepts types you add. A **CustomResourceDefinition** (CRD) registers a new type. A **controller** watches objects of that type and changes the cluster to match them. A CRD plus a controller is an **operator**.

Polyphone's platform team ships one. A product team does not write a Deployment to get media capacity. It creates a **MediaTenant**, a custom resource that declares a tier and a replica count. The **tenant-operator** creates a child media Deployment of the right size, links the child back to the MediaTenant with an **ownerReference**, and writes progress into the tenant's `.status`.

This tour runs on the full Polyphone fleet on a 2-node cluster: one tainted control-plane node and one worker. It adds the CRD, the operator and two healthy tenants, `orion` and `lyra`. Nothing is broken. You learn to read a working operator, so a stuck one stands out later.

Five short steps:

1. **The CRD** — the new `MediaTenant` type, served like a built-in
2. **Custom resources** — the `.spec` you declare and the `.status` the operator writes
3. **The operator** — the child Deployments it created, and the three places to read operator state
4. **Owner references** — the link that cascading deletion follows
5. **Self-heal and cascade** — delete a child and watch it return, then delete a tenant and watch its tree go

The cluster takes 90–150 seconds to come up, and the operator needs a few more seconds to reconcile. Click **Start** when ready.
