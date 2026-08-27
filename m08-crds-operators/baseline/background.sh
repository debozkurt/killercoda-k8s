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

kubectl wait --for=condition=Available deployment --all -A --timeout=120s >/dev/null 2>&1
# StatefulSets don't have an Available condition; wait for at least one ready pod
for ns in media signaling app-services edge; do
  kubectl wait --for=condition=Ready pod -l plane -n "$ns" --timeout=120s >/dev/null 2>&1
done

# ===========================================================================
# M08 platform additions — the CRD + operator + tenant CRs this module teaches.
# A CustomResourceDefinition (MediaTenant) extends the API with a new noun; a
# small controller (tenant-operator) reconciles each MediaTenant into a child
# media Deployment, stamps an ownerReference back to the CR, and reports progress
# in .status. Nothing here is broken — this is the healthy reference the tour reads.
# ===========================================================================

kubectl create namespace platform --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# --- The CustomResourceDefinition: teach the API server a new type ----------
cat <<'EOF' | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: mediatenants.polyphone.example
  labels: { plane: platform, tier: lab }
spec:
  group: polyphone.example
  scope: Namespaced
  names:
    plural: mediatenants
    singular: mediatenant
    kind: MediaTenant
    shortNames: [mt]
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
              required: [tier, replicas]
              properties:
                tier:
                  type: string
                  enum: [gold, silver, bronze]
                  description: Service tier for the tenant's media capacity.
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 5
                  description: Media-engine replicas to provision for this tenant.
            status:
              type: object
              properties:
                phase:
                  type: string
                readyReplicas:
                  type: integer
      subresources:
        status: {}
      additionalPrinterColumns:
        - { name: Tier,    type: string,  jsonPath: .spec.tier }
        - { name: Desired, type: integer, jsonPath: .spec.replicas }
        - { name: Ready,   type: integer, jsonPath: .status.readyReplicas }
        - { name: Phase,   type: string,  jsonPath: .status.phase }
        - { name: Age,     type: date,    jsonPath: .metadata.creationTimestamp }
EOF

kubectl wait --for=condition=Established crd/mediatenants.polyphone.example --timeout=60s >/dev/null 2>&1

# --- Operator RBAC: the ServiceAccount the controller authenticates as, and
#     the ClusterRole granting exactly the verbs its reconcile loop needs:
#     read MediaTenants + write their /status, and manage child Deployments.
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tenant-operator
  namespace: platform
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: tenant-operator
  labels: { plane: platform, tier: lab }
rules:
  - apiGroups: ["polyphone.example"]
    resources: ["mediatenants"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["polyphone.example"]
    resources: ["mediatenants/status"]
    verbs: ["get", "update", "patch"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tenant-operator
  labels: { plane: platform, tier: lab }
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tenant-operator
subjects:
  - kind: ServiceAccount
    name: tenant-operator
    namespace: platform
EOF

# --- The operator: a control loop that reconciles every MediaTenant into a
#     child media Deployment (owner-referenced back to the CR) and writes .status.
#     Deliberately a small kubectl reconcile loop so the pattern is legible, not a
#     compiled controller. `kubectl` in a Pod uses the mounted ServiceAccount.
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tenant-operator
  namespace: platform
  labels: { app: tenant-operator, plane: platform, tier: lab }
spec:
  replicas: 1
  selector: { matchLabels: { app: tenant-operator } }
  template:
    metadata:
      labels: { app: tenant-operator, plane: platform, tier: lab }
    spec:
      serviceAccountName: tenant-operator
      containers:
        - name: operator
          image: bitnami/kubectl:1.31
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "[tenant-operator] reconcile loop starting"
              while true; do
                for row in $(kubectl get mediatenants -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}' 2>/dev/null); do
                  ns="${row%%/*}"; name="${row##*/}"
                  [ -z "$name" ] && continue
                  replicas="$(kubectl get mediatenant "$name" -n "$ns" -o jsonpath='{.spec.replicas}' 2>/dev/null)"
                  uid="$(kubectl get mediatenant "$name" -n "$ns" -o jsonpath='{.metadata.uid}' 2>/dev/null)"
                  child="${name}-media"
                  if ! kubectl get deployment "$child" -n "$ns" >/dev/null 2>&1; then
                    echo "[tenant-operator] $ns/$name: creating child deployment $child (replicas=$replicas)"
                    kubectl create deployment "$child" -n "$ns" --image=nginx:1.25 --replicas="$replicas"
                  fi
                  kubectl scale deployment "$child" -n "$ns" --replicas="$replicas" >/dev/null 2>&1
                  kubectl label deployment "$child" -n "$ns" managed-by=tenant-operator plane=media tier=lab --overwrite >/dev/null 2>&1
                  kubectl patch deployment "$child" -n "$ns" --type=merge -p "{\"metadata\":{\"ownerReferences\":[{\"apiVersion\":\"polyphone.example/v1\",\"kind\":\"MediaTenant\",\"name\":\"$name\",\"uid\":\"$uid\",\"controller\":true,\"blockOwnerDeletion\":false}]}}" >/dev/null 2>&1
                  ready="$(kubectl get deployment "$child" -n "$ns" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
                  ready="${ready:-0}"
                  phase="Provisioning"; [ "$ready" = "$replicas" ] && phase="Ready"
                  kubectl patch mediatenant "$name" -n "$ns" --subresource=status --type=merge -p "{\"status\":{\"phase\":\"$phase\",\"readyReplicas\":$ready}}" >/dev/null 2>&1
                  echo "[tenant-operator] $ns/$name: phase=$phase readyReplicas=$ready desired=$replicas"
                done
                sleep 10
              done
          resources:
            requests: { cpu: 25m, memory: 64Mi }
            limits:   { cpu: 200m, memory: 128Mi }
EOF

# --- The tenants: two MediaTenant CRs the operator reconciles into capacity.
cat <<'EOF' | kubectl apply -f -
apiVersion: polyphone.example/v1
kind: MediaTenant
metadata: { name: orion, namespace: media, labels: { plane: media, tier: lab } }
spec: { tier: gold, replicas: 2 }
---
apiVersion: polyphone.example/v1
kind: MediaTenant
metadata: { name: lyra, namespace: media, labels: { plane: media, tier: lab } }
spec: { tier: silver, replicas: 1 }
EOF

# Give the operator a moment to reconcile both tenants into child Deployments.
for i in $(seq 1 40); do
  kubectl get deployment orion-media -n media >/dev/null 2>&1 && \
  kubectl get deployment lyra-media  -n media >/dev/null 2>&1 && break
  sleep 3
done
kubectl rollout status deployment/orion-media -n media --timeout=90s >/dev/null 2>&1
kubectl rollout status deployment/lyra-media  -n media --timeout=90s >/dev/null 2>&1

touch /tmp/.setup-complete
