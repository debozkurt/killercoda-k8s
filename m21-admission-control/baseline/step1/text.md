# Step 1 — The webhook backend and its two configurations

A webhook does nothing until a configuration object registers it. Here the backend is `admission-guard` — a small HTTPS server — and two objects point the API server at it: one mutating, one validating. See the server running, then read what each configuration intercepts and how it reaches the server.

## The backend server

```bash
kubectl get pods,svc -n admission
```{{exec}}

One `admission-guard` Pod `Running`, and a `Service` on port 443. The Service's in-cluster DNS name, `admission-guard.admission.svc`, is the address the API server will call — and the name baked into the server's TLS certificate.

## The two configurations that register it

```bash
kubectl get mutatingwebhookconfiguration,validatingwebhookconfiguration | grep admission-guard
```{{exec}}

Two objects, both named `admission-guard`. Read the validating one field by field:

```bash
kubectl get validatingwebhookconfiguration admission-guard -o yaml | sed -n '/webhooks:/,$p'
```{{exec}}

Four fields carry the whole behavior. `clientConfig.service` is *where* to call (`admission-guard` in `admission`, path `/validate`), and `caBundle` is the CA the API server uses to trust the server's cert. `rules` is *what* it intercepts — `CREATE` of core `v1` `pods`. `namespaceSelector` narrows that to namespaces labeled `admission-guard=enabled` (only `tenant-apps` carries it). `failurePolicy: Fail` says *if you can't reach me, reject the request.* The mutating configuration is the same shape with `path: /mutate`.

That is the entire contract: this webhook fires on Pod creates in `tenant-apps`, and nowhere else.
