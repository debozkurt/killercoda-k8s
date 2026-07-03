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
WORKER=$(kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.node-role\.kubernetes\.io/control-plane}{"\n"}{end}' | awk '$2=="" {print $1; exit}')
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
# M11 secrets-at-scale additions — a legible, offline stand-in for the External
# Secrets Operator. A `SecretSync` custom resource models an ESO `ExternalSecret`;
# the `secret-operator` reconcile loop reads a backing store (`vault-backend` in
# `secrets-source`, standing in for Vault / a cloud secrets manager) and materializes
# a Kubernetes Secret for each consumer, reporting progress in `.status`. Nothing here
# is broken — this is the healthy pipeline the baseline tour reads before the
# break/fix scenarios snap one link.
# ===========================================================================

kubectl create namespace secrets-source --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create namespace secrets-system --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# --- The backing store: a Secret standing in for an external secrets manager.
#     It holds more keys than any one consumer needs (signing-key is unused here),
#     the way a real Vault path holds many fields. The operator reads from it; it is
#     NOT wired into any Pod directly.
kubectl create secret generic vault-backend \
    --from-literal=db-password='S3cure-prod-4417' \
    --from-literal=api-token='pt_live_9c2f8a1b7e004d3a' \
    --from-literal=signing-key='sk_a4d1c0b93f2e5187' \
    -n secrets-source --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# --- Operator RBAC: the ServiceAccount the reconcile loop authenticates as, and the
#     access it needs, split so each grant is legible and independently auditable:
#       * a ClusterRole to watch SecretSyncs and write their /status (cluster-wide);
#       * a reusable secrets ClusterRole, bound per-namespace via RoleBindings — one
#         to READ the backing store (secrets-source), one to WRITE the target Secret
#         in each consumer namespace (provisioning, media). Least privilege: the
#         operator can touch secrets only where its job requires, nowhere else.
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secret-operator
  namespace: secrets-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-operator
  labels: { plane: security, tier: lab }
rules:
  - apiGroups: ["polyphone.example"]
    resources: ["secretsyncs"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["polyphone.example"]
    resources: ["secretsyncs/status"]
    verbs: ["get", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: secret-operator
  labels: { plane: security, tier: lab }
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: secret-operator
subjects:
  - kind: ServiceAccount
    name: secret-operator
    namespace: secrets-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-operator-secrets
  labels: { plane: security, tier: lab }
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secret-operator-store
  namespace: secrets-source
  labels: { plane: security, tier: lab }
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: secret-operator-secrets
subjects:
  - kind: ServiceAccount
    name: secret-operator
    namespace: secrets-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secret-operator-targets
  namespace: provisioning
  labels: { plane: security, tier: lab }
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: secret-operator-secrets
subjects:
  - kind: ServiceAccount
    name: secret-operator
    namespace: secrets-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secret-operator-targets
  namespace: media
  labels: { plane: security, tier: lab }
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: secret-operator-secrets
subjects:
  - kind: ServiceAccount
    name: secret-operator
    namespace: secrets-system
EOF

# --- The SecretSync CRD: a first-class type modeling an ESO ExternalSecret. spec
#     names the store, the target Secret, and the sourceKey->secretKey mapping;
#     status carries the sync result the operator writes (ready/reason/syncedKeys).
cat <<'EOF' | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: secretsyncs.polyphone.example
  labels: { plane: security, tier: lab }
spec:
  group: polyphone.example
  scope: Namespaced
  names:
    plural: secretsyncs
    singular: secretsync
    kind: SecretSync
    shortNames: [ssync]
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              required: [storeRef, target, data]
              properties:
                storeRef:
                  type: object
                  required: [name]
                  properties:
                    name:
                      type: string
                      description: Backing store to read (a Secret in the secrets-source namespace).
                target:
                  type: object
                  required: [name]
                  properties:
                    name:
                      type: string
                      description: Name of the Kubernetes Secret to materialize in this namespace.
                data:
                  type: array
                  minItems: 1
                  items:
                    type: object
                    required: [secretKey, sourceKey]
                    properties:
                      secretKey:
                        type: string
                        description: Key to write in the target Secret.
                      sourceKey:
                        type: string
                        description: Key to read from the backing store.
            status:
              type: object
              properties:
                ready:      { type: string }
                reason:     { type: string }
                message:    { type: string }
                syncedKeys: { type: string }
      subresources:
        status: {}
      additionalPrinterColumns:
        - { name: Store,  type: string, jsonPath: .spec.storeRef.name }
        - { name: Target, type: string, jsonPath: .spec.target.name }
        - { name: Ready,  type: string, jsonPath: .status.ready }
        - { name: Reason, type: string, jsonPath: .status.reason }
        - { name: Age,    type: date,   jsonPath: .metadata.creationTimestamp }
EOF

kubectl wait --for=condition=Established crd/secretsyncs.polyphone.example --timeout=60s >/dev/null 2>&1

# --- The operator: a level-triggered reconcile loop (a small kubectl-in-a-pod
#     controller, kept legible on purpose — the same shape as a compiled ESO). For
#     each SecretSync it (1) reads the backing store, (2) maps each sourceKey to a
#     secretKey, (3) refuses to materialize a partial Secret if a source key is
#     missing, and (4) writes the target Secret and reports Synced in .status.
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secret-operator
  namespace: secrets-system
  labels: { app: secret-operator, plane: security, tier: lab }
spec:
  replicas: 1
  selector: { matchLabels: { app: secret-operator } }
  template:
    metadata:
      labels: { app: secret-operator, plane: security, tier: lab }
    spec:
      serviceAccountName: secret-operator
      containers:
        - name: operator
          image: bitnami/kubectl:1.31
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "[secret-operator] reconcile loop starting"
              while true; do
                for row in $(kubectl get secretsyncs -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}' 2>/dev/null); do
                  ns="${row%%/*}"; name="${row##*/}"
                  [ -z "$name" ] && continue
                  store="$(kubectl get secretsync "$name" -n "$ns" -o jsonpath='{.spec.storeRef.name}' 2>/dev/null)"
                  target="$(kubectl get secretsync "$name" -n "$ns" -o jsonpath='{.spec.target.name}' 2>/dev/null)"

                  # 1) Can the operator read the backing store? (Its RoleBinding in secrets-source.)
                  if ! kubectl get secret "$store" -n secrets-source -o jsonpath='{.metadata.name}' >/dev/null 2>&1; then
                    kubectl patch secretsync "$name" -n "$ns" --subresource=status --type=merge -p "{\"status\":{\"ready\":\"False\",\"reason\":\"StoreNotReady\",\"message\":\"cannot read backing store secrets-source/$store\",\"syncedKeys\":\"\"}}" >/dev/null 2>&1
                    echo "[secret-operator] $ns/$name: StoreNotReady (cannot read secrets-source/$store)"
                    continue
                  fi

                  # 2) Map each sourceKey -> secretKey, reading values from the store.
                  pairs="$(kubectl get secretsync "$name" -n "$ns" -o jsonpath='{range .spec.data[*]}{.secretKey}={.sourceKey} {end}' 2>/dev/null)"
                  data_json=""; missing=""; synced=""
                  for pair in $pairs; do
                    sk="${pair%%=*}"; src="${pair##*=}"
                    [ -z "$sk" ] && continue
                    val="$(kubectl get secret "$store" -n secrets-source -o jsonpath="{.data['$src']}" 2>/dev/null)"
                    if [ -z "$val" ]; then missing="$missing $src"; else data_json="$data_json\"$sk\":\"$val\","; synced="$synced $sk"; fi
                  done

                  # 3) A missing source key is a SyncError — never materialize a partial Secret.
                  if [ -n "$missing" ]; then
                    kubectl patch secretsync "$name" -n "$ns" --subresource=status --type=merge -p "{\"status\":{\"ready\":\"False\",\"reason\":\"SyncError\",\"message\":\"source keys not found in store:$missing\",\"syncedKeys\":\"\"}}" >/dev/null 2>&1
                    echo "[secret-operator] $ns/$name: SyncError (missing in store:$missing)"
                    continue
                  fi

                  # 4) Materialize the target Secret; values are copied base64-for-base64 from the store.
                  printf 'apiVersion: v1\nkind: Secret\nmetadata:\n  name: %s\n  namespace: %s\n  labels: { managed-by: secret-operator, plane: security, tier: lab }\ntype: Opaque\ndata: { %s }\n' "$target" "$ns" "${data_json%,}" | kubectl apply -f - >/dev/null 2>&1
                  kubectl patch secretsync "$name" -n "$ns" --subresource=status --type=merge -p "{\"status\":{\"ready\":\"True\",\"reason\":\"Synced\",\"message\":\"materialized $ns/$target\",\"syncedKeys\":\"$synced\"}}" >/dev/null 2>&1
                  echo "[secret-operator] $ns/$name: Synced -> $ns/$target (keys:$synced)"
                done
                sleep 10
              done
          resources:
            requests: { cpu: 25m, memory: 64Mi }
            limits:   { cpu: 200m, memory: 128Mi }
EOF

kubectl rollout status deployment/secret-operator -n secrets-system --timeout=90s >/dev/null 2>&1

# --- The SecretSync objects: two synced credentials the operator materializes.
#     db-credentials (provisioning) feeds billing-processor; partner-api (media)
#     feeds partner-connector. Each names store keys, it does not contain them —
#     the GitOps-safe stand-in for a plaintext Secret.
cat <<'EOF' | kubectl apply -f -
apiVersion: polyphone.example/v1
kind: SecretSync
metadata:
  name: db-credentials
  namespace: provisioning
  labels: { plane: control, tier: lab }
spec:
  storeRef: { name: vault-backend }
  target:   { name: db-credentials }
  data:
    - { secretKey: DB_PASSWORD, sourceKey: db-password }
---
apiVersion: polyphone.example/v1
kind: SecretSync
metadata:
  name: partner-api
  namespace: media
  labels: { plane: media, tier: lab }
spec:
  storeRef: { name: vault-backend }
  target:   { name: partner-api }
  data:
    - { secretKey: API_TOKEN, sourceKey: api-token }
EOF

# Give the operator a couple of reconcile passes to materialize both target Secrets
# before starting the consumers, so they come up cleanly on the first try.
for i in $(seq 1 40); do
  kubectl get secret db-credentials -n provisioning >/dev/null 2>&1 && \
  kubectl get secret partner-api    -n media        >/dev/null 2>&1 && break
  sleep 3
done

# --- The consumers: two workloads that read their materialized Secret as an env var
#     (frozen at container start, per M03). They reference the target Secret by name
#     exactly like any Secret — they never know the operator exists.
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: billing-processor
  namespace: provisioning
  labels: { app: billing-processor, plane: control, tier: lab }
spec:
  replicas: 1
  selector: { matchLabels: { app: billing-processor } }
  template:
    metadata:
      labels: { app: billing-processor, plane: control, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          env:
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef: { name: db-credentials, key: DB_PASSWORD }
          ports: [{ containerPort: 80 }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: partner-connector
  namespace: media
  labels: { app: partner-connector, plane: media, tier: lab }
spec:
  replicas: 1
  selector: { matchLabels: { app: partner-connector } }
  template:
    metadata:
      labels: { app: partner-connector, plane: media, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          env:
            - name: API_TOKEN
              valueFrom:
                secretKeyRef: { name: partner-api, key: API_TOKEN }
          ports: [{ containerPort: 80 }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
EOF

kubectl rollout status deployment/billing-processor -n provisioning --timeout=90s >/dev/null 2>&1
kubectl rollout status deployment/partner-connector -n media        --timeout=90s >/dev/null 2>&1

touch /tmp/.setup-complete
