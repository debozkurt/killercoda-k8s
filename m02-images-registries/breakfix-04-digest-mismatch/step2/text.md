# Step 2 — Fix it and verify

The reference must name content the registry actually has. Re-pin to a digest that exists — keeping the immutability you pinned for in the first place.

## Re-pin to a real digest

Resolve the intended tag to its real digest and set it:

```bash
DIGEST=$(crane digest nginx:1.25)
echo "real digest: $DIGEST"
kubectl set image deployment/directory app=nginx@${DIGEST} -n app-services
```{{exec}}

The Deployment rolls a new pod, the kubelet requests a manifest that exists, and the pull succeeds — still digest-pinned, just to the right bytes.

## Or fall back to the tag

If you don't need digest-pinning for this workload, the tag is the simpler fix:

```bash
kubectl set image deployment/directory app=nginx:1.25 -n app-services
```

Both recover the pod. The difference is reproducibility: a tag can move later; the digest can't. For anything you need byte-identical across restarts and regions, re-pin the *correct* digest rather than dropping to a tag.

## Verify

```bash
kubectl get pods -n app-services -l app=directory
kubectl describe deploy directory -n app-services
```{{exec}}

`directory` is `Running` `1/1`, and in the `Pod Template` the `Image:` line no longer carries the all-zeros digest. The reference resolves, so the pull succeeds.

That's the last branch of the differential. For self-grading, the promotion-by-digest production angle, and a recap of all four causes, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
