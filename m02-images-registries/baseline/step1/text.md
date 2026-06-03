# Step 1 — Anatomy of an image reference

Every container starts from an image named by a *reference*. Learn to read one and you can read every pull failure that follows.

## List the images the fleet is actually running

```bash
kubectl get pods -A -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' | sort -u
```{{exec}}

Most of the fleet runs `nginx:1.25` — pulled anonymously from Docker Hub. One line stands out: `localhost:5000/polyphone/media-recorder:1.4.2`. That's the proprietary image, pulled from the in-cluster private registry.

## Read the four parts

A full reference has up to four parts. Take `media-recorder`'s:

```text
localhost:5000 / polyphone/media-recorder : 1.4.2
└── registry ──┘ └──── repository ───────┘ └tag┘
```

- **registry** — the server that serves the image. Omit it and the runtime defaults to Docker Hub (`docker.io`). That's why `nginx:1.25` has no registry prefix.
- **repository** — the named image within that registry.
- **tag** — a human-friendly pointer to a version. Omit it and it defaults to `:latest`.

So `nginx:1.25` is really `docker.io/library/nginx:1.25` — the registry and the `library/` namespace are just defaulted away.

## See the defaults made explicit

The pod's *status* shows the fully-qualified image the runtime resolved — read it off the YAML:

```bash
kubectl get pod -n analytics -l app=metrics-aggregator -o yaml
```{{exec}}

Down in `status:`, under `containerStatuses:`, find the `image:` line:

```text
  containerStatuses:
  - image: docker.io/library/nginx:1.25
```

That's the same `nginx:1.25` you wrote, with its defaults filled in. The reference you *write* is shorthand; the reference the runtime *resolves* is fully qualified.

Reading references fluently is the foundation: every break/fix in this module is a reference that the kubelet couldn't turn into bytes, and the fix always starts with knowing exactly which part of the reference — or the credentials behind it — is wrong.
