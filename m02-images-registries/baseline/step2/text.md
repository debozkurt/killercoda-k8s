# Step 2 — Tags move, digests don't

A tag is a *mutable* pointer; a digest is an *immutable* content address. This distinction decides how you pin production images — and is the whole of `breakfix-04`.

## Resolve a tag to its digest

A digest is the `sha256:` hash of the image's content. `crane` (installed for you) asks the registry what digest a tag currently points at:

```bash
crane digest nginx:1.25
```{{exec}}

You'll get something like `sha256:9f2a…`. That hash names *exactly those bytes*. `nginx:1.25` is a label that currently points there — but the registry owner could push new bytes to `nginx:1.25` tomorrow, and the tag would point somewhere else. The digest never moves: if the content changes, the digest changes.

## See the digest the node actually pulled

The kubelet records the resolved digest in the pod's `imageID`:

```bash
kubectl get pod -n analytics -l app=metrics-aggregator \
  -o jsonpath='{.items[0].status.containerStatuses[0].imageID}{"\n"}'
```{{exec}}

That `...@sha256:...` is the immutable identity of what's running — independent of the `nginx:1.25` tag it was requested by. Two nodes that both pulled `nginx:1.25` will show the same `imageID` only if the tag hadn't moved between their pulls.

## Why production pins by digest

Pin a workload to `...@sha256:9f2a…` instead of `:1.25` and you guarantee every node, every restart, every region runs byte-identical code — a tag is a promise the registry can break, a digest is a fact. It's also the anchor signing and promotion ride on: you sign a digest, and you promote the *same* digest across environments rather than re-resolving a tag.

The cost is fail-closed behavior: get the digest wrong and the pull fails with `manifest unknown` rather than silently running something else. That safety feature is exactly what `breakfix-04` exercises.
