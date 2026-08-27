#!/bin/bash
#
# Polyphone baseline — the canonical known-good cluster.
# Spins up the full 17-workload fleet across 10 namespaces.
#
# This file is the source of truth. Per-lesson scenarios should copy it into
# their own directory and append mutations to create broken-cluster siblings.

set +e  # don't abort on individual kubectl errors during setup

# ---------------------------------------------------------------------------
# Wait for the cluster to be ready
# ---------------------------------------------------------------------------
while ! kubectl get nodes 2>/dev/null | grep -q " Ready"; do
  sleep 2
done
sleep 5

# ---------------------------------------------------------------------------
# Cluster prerequisites
# ---------------------------------------------------------------------------

# local-path-provisioner so PVC workloads work (RWO only)
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml >/dev/null 2>&1
kubectl wait --for=condition=Ready pods -l app=local-path-provisioner -n local-path-storage --timeout=60s >/dev/null 2>&1

# metrics-server so kubectl top works
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml >/dev/null 2>&1
kubectl patch deployment metrics-server -n kube-system --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' >/dev/null 2>&1

# k9s for the TUI-inclined
curl -sL https://github.com/derailed/k9s/releases/download/v0.32.7/k9s_Linux_amd64.tar.gz \
  | tar xz -C /usr/local/bin k9s 2>/dev/null

# Label the worker node disktype=ssd so node-affinity workloads schedule cleanly
# Never the control-plane node: its control-plane label carries an EMPTY value,
# so a "field is blank" test matches it. Select by label negation instead.
WORKER=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
[ -z "$WORKER" ] && WORKER=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl label node "$WORKER" disktype=ssd --overwrite >/dev/null 2>&1

# >>> M20 setup: install the Kyverno policy engine (the admission-control front door).
#     Kicked off here, before the fleet, so its image pulls overlap fleet creation; we
#     wait for it near the end. Pinned to a known-good release. Kyverno installs its CRDs
#     (ClusterPolicy, PolicyReport, ...) and four controllers into the `kyverno` namespace;
#     the admission controller registers the validating/mutating webhooks. `create` (not
#     `apply`) is Kyverno's documented install method — its CRDs are too large for apply's
#     last-applied-configuration annotation.
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.14.5/install.yaml >/dev/null 2>&1
# <<< M20 setup ends

# Common label injected on every workload below: `plane=<arch-plane>`, `tier=lab`.

# ===========================================================================
# media plane
# ===========================================================================

kubectl create namespace media --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# media-engine — StatefulSet, 2 replicas, PVC each (represents RTP media servers)
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: media-engine
  namespace: media
  labels: { app: media-engine, plane: media, tier: lab }
spec:
  clusterIP: None
  selector: { app: media-engine }
  ports: [{ port: 5004, name: rtp }]
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: media-engine
  namespace: media
  labels: { app: media-engine, plane: media, tier: lab }
spec:
  serviceName: media-engine
  replicas: 2
  selector: { matchLabels: { app: media-engine } }
  template:
    metadata:
      labels: { app: media-engine, plane: media, tier: lab }
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - { key: disktype, operator: In, values: [ssd] }
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 5004, name: rtp }]
          resources:
            requests: { cpu: 50m, memory: 64Mi }
            limits:   { cpu: 200m, memory: 128Mi }
          volumeMounts:
            - { name: state, mountPath: /var/state }
  volumeClaimTemplates:
    - metadata: { name: state }
      spec:
        accessModes: [ReadWriteOnce]
        storageClassName: local-path
        resources: { requests: { storage: 100Mi } }
EOF

# session-broker — Deployment + Service
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: session-broker
  namespace: media
  labels: { app: session-broker, plane: media, tier: lab }
spec:
  replicas: 1
  selector: { matchLabels: { app: session-broker } }
  template:
    metadata:
      labels: { app: session-broker, plane: media, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 80 }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
---
apiVersion: v1
kind: Service
metadata:
  name: session-broker
  namespace: media
  labels: { app: session-broker, plane: media, tier: lab }
spec:
  selector: { app: session-broker }
  ports: [{ port: 80, targetPort: 80 }]
EOF

# transcoder — Deployment with nodeAffinity
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: transcoder
  namespace: media
  labels: { app: transcoder, plane: media, tier: lab }
spec:
  replicas: 1
  selector: { matchLabels: { app: transcoder } }
  template:
    metadata:
      labels: { app: transcoder, plane: media, tier: lab }
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - { key: disktype, operator: In, values: [ssd] }
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 80 }]
          resources:
            requests: { cpu: 50m, memory: 32Mi }
            limits:   { cpu: 200m, memory: 64Mi }
EOF

# ===========================================================================
# signaling plane
# ===========================================================================

kubectl create namespace signaling --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# sip-router — Deployment + Service, 2 replicas
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sip-router
  namespace: signaling
  labels: { app: sip-router, plane: signaling, tier: lab }
spec:
  replicas: 2
  selector: { matchLabels: { app: sip-router } }
  template:
    metadata:
      labels: { app: sip-router, plane: signaling, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 5060, name: sip }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
---
apiVersion: v1
kind: Service
metadata:
  name: sip-router
  namespace: signaling
  labels: { app: sip-router, plane: signaling, tier: lab }
spec:
  selector: { app: sip-router }
  ports: [{ port: 5060, targetPort: 5060, name: sip }]
EOF

# sip-proxy — Deployment + Service, 2 replicas
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sip-proxy
  namespace: signaling
  labels: { app: sip-proxy, plane: signaling, tier: lab }
spec:
  replicas: 2
  selector: { matchLabels: { app: sip-proxy } }
  template:
    metadata:
      labels: { app: sip-proxy, plane: signaling, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 5060, name: sip }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
---
apiVersion: v1
kind: Service
metadata:
  name: sip-proxy
  namespace: signaling
  labels: { app: sip-proxy, plane: signaling, tier: lab }
spec:
  selector: { app: sip-proxy }
  ports: [{ port: 5060, targetPort: 5060, name: sip }]
EOF

# reg-proxy — StatefulSet + Headless Service, 2 replicas
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: reg-proxy
  namespace: signaling
  labels: { app: reg-proxy, plane: signaling, tier: lab }
spec:
  clusterIP: None
  selector: { app: reg-proxy }
  ports: [{ port: 5060, name: sip }]
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: reg-proxy
  namespace: signaling
  labels: { app: reg-proxy, plane: signaling, tier: lab }
spec:
  serviceName: reg-proxy
  replicas: 2
  selector: { matchLabels: { app: reg-proxy } }
  template:
    metadata:
      labels: { app: reg-proxy, plane: signaling, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 5060, name: sip }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
EOF

# ===========================================================================
# app-services plane
# ===========================================================================

kubectl create namespace app-services --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# sip-app — Deployment + Service (the SIP application server)
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sip-app
  namespace: app-services
  labels: { app: sip-app, plane: app, tier: lab }
spec:
  replicas: 1
  selector: { matchLabels: { app: sip-app } }
  template:
    metadata:
      labels: { app: sip-app, plane: app, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 8080 }]
          resources:
            requests: { cpu: 50m, memory: 64Mi }
            limits:   { cpu: 200m, memory: 128Mi }
---
apiVersion: v1
kind: Service
metadata:
  name: sip-app
  namespace: app-services
  labels: { app: sip-app, plane: app, tier: lab }
spec:
  selector: { app: sip-app }
  ports: [{ port: 80, targetPort: 8080 }]
EOF

# presence — StatefulSet + PVC
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: presence
  namespace: app-services
  labels: { app: presence, plane: app, tier: lab }
spec:
  clusterIP: None
  selector: { app: presence }
  ports: [{ port: 80 }]
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: presence
  namespace: app-services
  labels: { app: presence, plane: app, tier: lab }
spec:
  serviceName: presence
  replicas: 1
  selector: { matchLabels: { app: presence } }
  template:
    metadata:
      labels: { app: presence, plane: app, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 80 }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
          volumeMounts:
            - { name: state, mountPath: /var/state }
  volumeClaimTemplates:
    - metadata: { name: state }
      spec:
        accessModes: [ReadWriteOnce]
        storageClassName: local-path
        resources: { requests: { storage: 100Mi } }
EOF

# directory — Deployment + PVC + Service
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: directory-data
  namespace: app-services
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: local-path
  resources: { requests: { storage: 200Mi } }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: directory
  namespace: app-services
  labels: { app: directory, plane: app, tier: lab }
spec:
  replicas: 1
  selector: { matchLabels: { app: directory } }
  template:
    metadata:
      labels: { app: directory, plane: app, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 80 }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
          volumeMounts:
            - { name: data, mountPath: /var/data }
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: directory-data
---
apiVersion: v1
kind: Service
metadata:
  name: directory
  namespace: app-services
  labels: { app: directory, plane: app, tier: lab }
spec:
  selector: { app: directory }
  ports: [{ port: 80, targetPort: 80 }]
EOF

# ===========================================================================
# edge plane
# ===========================================================================

kubectl create namespace edge --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# sbc-edge — DaemonSet (one per node)
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: sbc-edge
  namespace: edge
  labels: { app: sbc-edge, plane: edge, tier: lab }
spec:
  selector: { matchLabels: { app: sbc-edge } }
  template:
    metadata:
      labels: { app: sbc-edge, plane: edge, tier: lab }
    spec:
      tolerations:
        - { key: node-role.kubernetes.io/control-plane, operator: Exists, effect: NoSchedule }
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 5060, name: sip }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
EOF

# pstn-gateway — StatefulSet + PVC
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: pstn-gateway
  namespace: edge
  labels: { app: pstn-gateway, plane: edge, tier: lab }
spec:
  clusterIP: None
  selector: { app: pstn-gateway }
  ports: [{ port: 5060, name: sip }]
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: pstn-gateway
  namespace: edge
  labels: { app: pstn-gateway, plane: edge, tier: lab }
spec:
  serviceName: pstn-gateway
  replicas: 1
  selector: { matchLabels: { app: pstn-gateway } }
  template:
    metadata:
      labels: { app: pstn-gateway, plane: edge, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 5060, name: sip }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
          volumeMounts:
            - { name: state, mountPath: /var/state }
  volumeClaimTemplates:
    - metadata: { name: state }
      spec:
        accessModes: [ReadWriteOnce]
        storageClassName: local-path
        resources: { requests: { storage: 100Mi } }
EOF

# ===========================================================================
# control / admin plane (existing single-namespace workloads)
# ===========================================================================

# provisioning ns: account-provisioner with secret
kubectl create namespace provisioning --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create secret generic database-creds \
    --from-literal=DB_HOST=postgres.polyphone.example \
    --from-literal=DB_PASSWORD=changeme \
    -n provisioning --dry-run=client -o yaml | kubectl apply -f - >/dev/null
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: account-provisioner
  namespace: provisioning
  labels: { app: account-provisioner, plane: control, tier: lab }
spec:
  replicas: 1
  selector: { matchLabels: { app: account-provisioner } }
  template:
    metadata:
      labels: { app: account-provisioner, plane: control, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          envFrom: [{ secretRef: { name: database-creds } }]
          ports: [{ containerPort: 80 }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
EOF

# admin-portal: portal-ui with Service
kubectl create namespace admin-portal --dry-run=client -o yaml | kubectl apply -f - >/dev/null
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portal-ui
  namespace: admin-portal
  labels: { app: portal-ui, plane: admin, tier: lab }
spec:
  replicas: 2
  selector: { matchLabels: { app: portal-ui } }
  template:
    metadata:
      labels: { app: portal-ui, plane: admin, tier: lab }
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports: [{ containerPort: 80 }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
---
apiVersion: v1
kind: Service
metadata:
  name: portal-ui
  namespace: admin-portal
  labels: { app: portal-ui, plane: admin, tier: lab }
spec:
  selector: { app: portal-ui }
  ports: [{ port: 80, targetPort: 80 }]
  type: ClusterIP
EOF

# call-routing: route-engine
kubectl create namespace call-routing --dry-run=client -o yaml | kubectl apply -f - >/dev/null
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: route-engine
  namespace: call-routing
  labels: { app: route-engine, plane: control, tier: lab }
spec:
  replicas: 2
  selector: { matchLabels: { app: route-engine } }
  template:
    metadata:
      labels: { app: route-engine, plane: control, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 80 }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
---
apiVersion: v1
kind: Service
metadata:
  name: route-engine
  namespace: call-routing
  labels: { app: route-engine, plane: control, tier: lab }
spec:
  selector: { app: route-engine }
  ports: [{ port: 80, targetPort: 80 }]
  type: ClusterIP
EOF

# cdr-storage: cdr-writer with PVC
kubectl create namespace cdr-storage --dry-run=client -o yaml | kubectl apply -f - >/dev/null
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cdr-data
  namespace: cdr-storage
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: local-path
  resources: { requests: { storage: 1Gi } }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cdr-writer
  namespace: cdr-storage
  labels: { app: cdr-writer, plane: control, tier: lab }
spec:
  replicas: 1
  selector: { matchLabels: { app: cdr-writer } }
  template:
    metadata:
      labels: { app: cdr-writer, plane: control, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          volumeMounts: [{ name: data, mountPath: /data }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
      volumes:
        - name: data
          persistentVolumeClaim: { claimName: cdr-data }
EOF

# analytics: metrics-aggregator
kubectl create namespace analytics --dry-run=client -o yaml | kubectl apply -f - >/dev/null
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-aggregator
  namespace: analytics
  labels: { app: metrics-aggregator, plane: control, tier: lab }
spec:
  replicas: 1
  selector: { matchLabels: { app: metrics-aggregator } }
  template:
    metadata:
      labels: { app: metrics-aggregator, plane: control, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 80 }]
          resources:
            requests: { cpu: 50m, memory: 64Mi }
            limits:   { cpu: 200m, memory: 128Mi }
EOF

# number-porting: port-processor with ResourceQuota
kubectl create namespace number-porting --dry-run=client -o yaml | kubectl apply -f - >/dev/null
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: pod-limit
  namespace: number-porting
spec:
  hard: { pods: "5" }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: port-processor
  namespace: number-porting
  labels: { app: port-processor, plane: control, tier: lab }
spec:
  replicas: 2
  selector: { matchLabels: { app: port-processor } }
  template:
    metadata:
      labels: { app: port-processor, plane: control, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 80 }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
EOF

# ---------------------------------------------------------------------------
# Wait for the fleet to come up
# ---------------------------------------------------------------------------

# Shorter ceilings — Killercoda caps background-script runtime. The mutation breaks a
# policy admission, not Pod health, so every fleet Pod still becomes Ready.
kubectl wait --for=condition=Available deployment --all -A --timeout=120s >/dev/null 2>&1
# StatefulSets don't have an Available condition; wait for at least one ready pod
for ns in media signaling app-services edge; do
  kubectl wait --for=condition=Ready pod -l plane -n "$ns" --timeout=60s >/dev/null 2>&1
done

# >>> M20 setup: Kyverno + the healthy policy set (shared with the baseline).
# Wait for the admission controller so its webhooks are live before we apply any policy.
kubectl wait --for=condition=Available deployment/kyverno-admission-controller \
  -n kyverno --timeout=150s >/dev/null 2>&1

# tenant-apps: where customer/tenant workloads are admitted under platform policy.
kubectl create namespace tenant-apps --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# Three ClusterPolicies, each scoped to `tenant-apps` (so they never match the 17-workload
# fleet in the other namespaces):
#   require-resource-limits (validate/Enforce) — every container must declare cpu+memory limits
#   add-owner-label         (mutate)           — inject owner=platform when absent
#   disallow-latest-tag     (validate/Enforce) — images must carry an explicit non-latest tag
# The two Enforce validate policies disable autogen, so a rejection of a controller-created
# Pod surfaces on the ReplicaSet (Deployment stuck 0/N) instead of at `kubectl apply` — the
# same inspectable signature PodSecurity gives in M10.
cat <<'EOF' | kubectl apply -f -
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
  annotations:
    pod-policies.kyverno.io/autogen-controllers: none
spec:
  rules:
    - name: require-limits
      match:
        any:
          - resources:
              kinds: [Pod]
              namespaces: [tenant-apps]
      validate:
        failureAction: Enforce
        message: "Resource limits (cpu and memory) are required for tenant workloads."
        pattern:
          spec:
            containers:
              - name: "*"
                resources:
                  limits:
                    memory: "?*"
                    cpu: "?*"
---
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
              +(owner): platform     # +() = add only if the label is absent; never overwrite
---
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
  annotations:
    pod-policies.kyverno.io/autogen-controllers: none
spec:
  rules:
    - name: require-non-latest
      match:
        any:
          - resources:
              kinds: [Pod]
              namespaces: [tenant-apps]
      validate:
        failureAction: Enforce
        message: "Images must use an explicit, non-latest tag (no :latest)."
        pattern:
          spec:
            containers:
              - name: "*"
                image: "!*:latest"
    - name: require-image-tag
      match:
        any:
          - resources:
              kinds: [Pod]
              namespaces: [tenant-apps]
      validate:
        failureAction: Enforce
        message: "An image tag is required (an untagged image defaults to :latest)."
        pattern:
          spec:
            containers:
              - name: "*"
                image: "*:*"
EOF

# Let Kyverno register the webhooks for the new policies before deploying anything into scope.
for p in require-resource-limits add-owner-label disallow-latest-tag; do
  kubectl wait --for=condition=Ready clusterpolicy/"$p" --timeout=60s >/dev/null 2>&1
done
sleep 8
# <<< M20 setup ends

# >>> breakfix-01 mutation: deploy billing-api with NO resource limits. require-resource-limits
#     (Enforce, autogen disabled) admits the Deployment but rejects the Pod its ReplicaSet
#     tries to create, so billing-api sits at 0/1 with no Pods and the denial on a FailedCreate
#     event on the ReplicaSet. The image is nginx:1.25 (tagged) so disallow-latest-tag passes —
#     the only violation is the missing limits. Fix = add resources.limits.{cpu,memory}.
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: billing-api
  namespace: tenant-apps
  labels: { app: billing-api, plane: tenant, tier: lab }
spec:
  replicas: 1
  selector: { matchLabels: { app: billing-api } }
  template:
    metadata:
      labels: { app: billing-api, plane: tenant, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 80 }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }   # MUTATED (baseline form also sets resources.limits — omitted here)
EOF
sleep 8   # let the ReplicaSet try (and fail) to create the Pod so the FailedCreate event lands
# <<< breakfix-01 mutation ends

touch /tmp/.setup-complete
