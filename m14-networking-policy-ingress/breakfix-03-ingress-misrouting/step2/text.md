# Step 2 — Fix it and verify

The backend port in the rule has to name a port the Service exposes. `portal-ui` exposes `80`, so point the rule at `80`.

## Correct the backend port

Re-apply the Ingress with the right port:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: portal
  namespace: admin-portal
spec:
  ingressClassName: nginx
  rules:
    - host: portal.polyphone.example
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: portal-ui
                port: { number: 80 }
EOF
```{{exec}}

Or edit the one field in place:

```bash
kubectl edit ingress portal -n admin-portal
# under backend.service.port, change  number: 8080  →  number: 80
```

The controller re-reads the Ingress and re-resolves the backend — now to `portal-ui:80`, which has endpoints.

## Verify

```bash
CIP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.clusterIP}')
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -n admin-portal -- \
  wget -qO- --timeout=5 --header "Host: portal.polyphone.example" "http://$CIP/"
```{{exec}}

nginx's HTML comes back instead of a `503` — the request now routes host → rule → `portal-ui:80` → a Ready Pod. Nothing about the Service or its Pods changed; only the port the rule named. For self-grading and the full differential, see [`ANSWER-KEY.md`](../ANSWER-KEY.md). You're done — see `finish.md`.
