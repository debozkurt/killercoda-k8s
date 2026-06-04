# Step 1 — Find the broken workload

The alert told you something is broken but not where. Your first move sets the tone for the entire incident.

Bad first move: opening namespaces one at a time hoping you guess right. That doesn't scale, and it feels productive while wasting minutes.

Good first move: ask the cluster what it knows, cluster-wide.

## Try the cluster-wide scan

```bash
kubectl get pods -A
```{{exec}}

Scan the `STATUS` column. Most pods should be `Running`. One workload will stand out — pods in `ImagePullBackOff` or `ErrImagePull` (the kubelet tried to fetch the container image, the registry said no, and the kubelet is now backing off retries with exponential delay).

## Alternative: sort events globally

If many things are wrong (or you want a chronological view), events are often the fastest path:

```bash
kubectl get events -A --sort-by='.lastTimestamp' | tail -30
```{{exec}}

Recent failures bubble to the bottom. You should see `Failed to pull image` events on the broken workload — even before any pod has settled into `ImagePullBackOff`.

## Zoom in

Once you've located the namespace and workload, run the next step of the diagnostic loop:

```bash
# (Substitute the namespace and label you found above.)
kubectl describe pod -n analytics -l app=metrics-aggregator
```{{exec}}

Look at the `Events:` section at the bottom. You'll see something like:

```text
  Warning  Failed  ...  Failed to pull image "nginx:doesnotexist-1.25-foobar":
                       ... not found
```

That's your root cause: the Deployment is referencing an image that doesn't exist. Most likely a typo or a bad tag pushed in an earlier change.

## Verify what you found

```bash
kubectl describe deployment metrics-aggregator -n analytics
```{{exec}}

In the `Pod Template` section, the container's `Image:` line shows the bad image string (`nginx:doesnotexist-1.25-foobar`). Move to step 2.
