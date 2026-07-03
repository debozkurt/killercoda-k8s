# Step 2 — Fix the policy and re-admit

Two moves: correct the policy's namespace so the rule matches, then re-admit the Pod so the mutation actually runs on it. The second move is the lesson — mutation happens only at admission.

## Correct the policy's match

Re-apply the policy with the right namespace (`tenant-apps`):

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-owner-label
spec:
  rules:
    - name: add-owner
      match:
        any:
          - resources:
              kinds: [Pod]
              namespaces: [tenant-apps]
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              +(owner): platform
EOF
```{{exec}}

## The label is still missing — and that's the point

```bash
kubectl get pods -n tenant-apps -L owner
```{{exec}}

`tenant-portal`'s Pod *still* has no `owner`. Fixing the policy didn't retro-fix the running Pod, because **a mutate rule only fires at admission** — on create or update — and this Pod passed admission before the rule matched anything. Correcting the policy changes what happens to the *next* Pod, not this one.

## Re-admit the Pod

Force new Pods through the (now-correct) webhook:

```bash
kubectl rollout restart deployment/tenant-portal -n tenant-apps
kubectl rollout status deployment/tenant-portal -n tenant-apps --timeout=60s
kubectl get pods -n tenant-apps -L owner
```{{exec}}

The replacement Pod goes through admission, the mutate rule matches it now, and it comes up carrying `owner=platform`. That two-step — fix the policy, then re-admit — is the whole muscle: correcting a mutation never reaches Pods that are already running. For self-grading, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
