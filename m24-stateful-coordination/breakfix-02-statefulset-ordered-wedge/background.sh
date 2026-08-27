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

kubectl wait --for=condition=Available deployment --all -A --timeout=240s >/dev/null 2>&1
# StatefulSets don't have an Available condition; wait for at least one ready pod
for ns in media signaling app-services edge; do
  kubectl wait --for=condition=Ready pod -l plane -n "$ns" --timeout=120s >/dev/null 2>&1
done


# ===========================================================================
# M24 enhancement — stateful-coordination workloads (session-cache + call-coordinator)
# >>> breakfix-02 mutation: session-cache's readiness probe points at port 8080,
#     where nothing listens (nginx serves on 80). Every replica would fail the
#     probe, but with the default OrderedReady podManagementPolicy the controller
#     will not create ordinal N+1 until ordinal N is Running AND Ready. So only
#     session-cache-0 is ever created — stuck 0/1 Running, never Ready — and
#     session-cache-1 and -2 never appear. The whole set is wedged behind ordinal 0.
#     Fix = correct the readiness probe port to 80; ordinal 0 goes Ready and the
#     controller creates the rest, in order.
# ===========================================================================
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: session-cache
  namespace: media
  labels: { app: session-cache, plane: media, tier: lab }
spec:
  clusterIP: None
  selector: { app: session-cache }
  ports: [{ port: 6379, name: cache }]
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: session-cache
  namespace: media
  labels: { app: session-cache, plane: media, tier: lab }
spec:
  serviceName: session-cache
  replicas: 3
  podManagementPolicy: OrderedReady
  selector: { matchLabels: { app: session-cache } }
  template:
    metadata:
      labels: { app: session-cache, plane: media, tier: lab }
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
          ports: [{ containerPort: 80, name: http }]
          readinessProbe:
            # MUTATED (baseline: port 80) — nginx serves on 80; nothing listens on
            # 8080, so this probe never passes and ordinal 0 never becomes Ready.
            httpGet: { path: /, port: 8080 }
            initialDelaySeconds: 3
            periodSeconds: 5
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
          volumeMounts:
            - { name: data, mountPath: /var/cache/session }
  volumeClaimTemplates:
    - metadata: { name: data }
      spec:
        accessModes: [ReadWriteOnce]
        storageClassName: local-path
        resources: { requests: { storage: 100Mi } }
EOF
# <<< breakfix-02 mutation ends

# call-coordinator — leader-elected singleton (healthy in this scenario)
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata: { name: coordinator, namespace: call-routing }
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: { name: leader-election, namespace: call-routing }
rules:
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: { name: leader-election, namespace: call-routing }
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: leader-election
subjects:
  - kind: ServiceAccount
    name: coordinator
    namespace: call-routing
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: call-coordinator
  namespace: call-routing
  labels: { app: call-coordinator, plane: control, tier: lab }
spec:
  replicas: 2
  selector: { matchLabels: { app: call-coordinator } }
  template:
    metadata:
      labels: { app: call-coordinator, plane: control, tier: lab }
    spec:
      serviceAccountName: coordinator
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 80 }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
EOF

# Do NOT wait on session-cache — it is wedged by design and would stall setup.
kubectl rollout status deployment/call-coordinator -n call-routing --timeout=90s >/dev/null 2>&1

# The Lease that records the current leader (call-coordinator is healthy here).
cat <<'EOF' | kubectl apply -f -
apiVersion: coordination.k8s.io/v1
kind: Lease
metadata: { name: call-coordinator, namespace: call-routing }
spec:
  holderIdentity: pending-election
  leaseDurationSeconds: 15
EOF
HOLDER=$(kubectl get pods -n call-routing -l app=call-coordinator \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
NOW=$(date -u +%Y-%m-%dT%H:%M:%S.000000Z)
kubectl patch lease call-coordinator -n call-routing --type=merge \
  -p "{\"spec\":{\"holderIdentity\":\"${HOLDER:-call-coordinator-0}\",\"acquireTime\":\"${NOW}\",\"renewTime\":\"${NOW}\"}}" >/dev/null 2>&1

touch /tmp/.setup-complete
