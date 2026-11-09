# Step 1 — Try the hand fix

## Read the consumer

```bash
flux get kustomizations
```{{exec}}

`apps` alternates between two states, about a minute each. `READY False` with `health check failed after 1m0s: timeout waiting for: [Deployment/app-services/dialplan status: 'InProgress']`, and `READY Unknown` with `Reconciliation in progress` while the controller retries. The `REVISION` column holds the seed commit. After about 10 minutes the Deployment passes its `progressDeadlineSeconds` (600 by default), and the status in the message changes from `'InProgress'` to `'Failed'`. The diagnosis is the same.

```bash
kubectl describe kustomization apps -n flux-system
git -C /root/polyphone-config log --oneline
```{{exec}}

Under `Status`, `Last Attempted Revision` is the release commit, and `Last Applied Revision` is the seed commit. The applied revision moves only when a pass succeeds, health check included. So the release commit was **applied** to the cluster, and the health check refused it.

## Read the workload

```bash
kubectl get pods -n app-services -l app=dialplan
kubectl describe deployment dialplan -n app-services
```{{exec}}

Two old Pods run, and one new Pod is in `ImagePullBackOff`. `Image:` reads `nginx:1.25-polyphone`, a tag the registry does not have. The rollout keeps the old Pods because the new one never becomes ready.

## Fix it by hand

The previous image was `nginx:1.25`. Set it with `kubectl`:

```bash
kubectl set image deployment/dialplan app=nginx:1.25 -n app-services
kubectl rollout status deployment/dialplan -n app-services
```{{exec}}

The rollout completes. Now wait for the next pass of `apps`, about a minute, and look again:

```bash
kubectl get pods -n app-services -l app=dialplan
kubectl describe deployment dialplan -n app-services
```{{exec}}

`Image:` is `nginx:1.25-polyphone` again, and a new Pod is back in `ImagePullBackOff`. Git declares the image, so every pass of kustomize-controller applies it again and takes the field back from `kubectl`. The hand fix cannot last. The desired state itself is wrong, and the desired state lives in git.
