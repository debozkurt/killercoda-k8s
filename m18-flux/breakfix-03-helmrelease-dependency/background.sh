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


# ===========================================================================
# >>> M18 addition: install Flux + an in-cluster git server, seed the config
#     repo, and wire up a GitOps delivery pipeline.
#
#     Flux is a GitOps controller: git holds the desired state, and Flux's
#     controllers (source / kustomize / helm) continuously reconcile the
#     cluster to match it. This block:
#       1. installs the pinned `flux` CLI and its controllers (`flux install`)
#       2. runs a tiny in-cluster Gitea git server (source for GitRepository)
#       3. seeds a config repo (an `apps` Kustomize dir + `voicemail` and
#          `message-store` Helm charts) and pushes it to Gitea
#       4. applies the Flux custom resources that reconcile that repo
#     Per-scenario mutations are appended AFTER this shared block.
# ===========================================================================

# --- 1. install the pinned flux CLI (fetch-and-extract, like helm/k9s above) --
FLUX_VERSION=2.8.6
curl -sL "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_amd64.tar.gz" \
  | tar xz -C /usr/local/bin flux 2>/dev/null
chmod +x /usr/local/bin/flux 2>/dev/null

# Install just the three controllers the GitRepository -> Kustomization ->
# HelmRelease chain needs. `flux install` needs no git provider or token
# (that is `flux bootstrap`); it lays the controllers into flux-system and
# waits for them to become ready.
flux install \
  --components=source-controller,kustomize-controller,helm-controller \
  --network-policy=false >/dev/null 2>&1

# --- 2. in-cluster Gitea (the git server behind the GitRepository source) -----
# source-controller (go-git) speaks smart HTTP; Gitea serves it out of the box.
# SQLite + emptyDir keeps it single-pod and disposable — this is a lab source of
# truth, not production storage. A NodePort lets the host seed the repo; Flux
# reaches it in-cluster over the ClusterIP DNS name.
cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitea
  namespace: flux-system
  labels: { app: gitea, plane: control, tier: lab }
spec:
  replicas: 1
  selector: { matchLabels: { app: gitea } }
  template:
    metadata:
      labels: { app: gitea, plane: control, tier: lab }
    spec:
      containers:
        - name: gitea
          image: gitea/gitea:1.24
          env:
            - { name: GITEA__database__DB_TYPE, value: sqlite3 }
            - { name: GITEA__security__INSTALL_LOCK, value: "true" }
            - { name: GITEA__service__DISABLE_REGISTRATION, value: "true" }
            - { name: GITEA__service__REQUIRE_SIGNIN_VIEW, value: "false" }
            - { name: GITEA__server__DISABLE_SSH, value: "true" }
            - { name: GITEA__server__ROOT_URL, value: "http://gitea.flux-system.svc.cluster.local:3000/" }
            - { name: GITEA__repository__DEFAULT_PUSH_CREATE_PRIVATE, value: "false" }
          ports:
            - { containerPort: 3000, name: http }
          resources:
            requests: { cpu: 50m, memory: 128Mi }
            limits:   { cpu: 500m, memory: 512Mi }
          volumeMounts:
            - { name: data, mountPath: /data }
      volumes:
        - name: data
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: gitea
  namespace: flux-system
  labels: { app: gitea, plane: control, tier: lab }
spec:
  type: NodePort
  selector: { app: gitea }
  ports:
    - { port: 3000, targetPort: 3000, nodePort: 30300, name: http }
EOF

kubectl rollout status deployment/gitea -n flux-system --timeout=120s >/dev/null 2>&1

# Wait until Gitea's HTTP API answers on the NodePort before seeding.
for i in $(seq 1 60); do
  curl -sf "http://localhost:30300/api/v1/version" >/dev/null 2>&1 && break
  sleep 2
done

# --- 3. seed the config repo -------------------------------------------------
# Create the admin user Flux will (anonymously) clone from, then a PUBLIC repo.
kubectl exec deploy/gitea -n flux-system -- \
  gitea admin user create --username flux --password flux-admin \
  --email flux@polyphone.example --admin --must-change-password=false >/dev/null 2>&1
curl -sf -u flux:flux-admin -X POST "http://localhost:30300/api/v1/user/repos" \
  -H 'Content-Type: application/json' \
  -d '{"name":"polyphone-config","private":false,"auto_init":false}' >/dev/null 2>&1

# Write the repo tree to /root/polyphone-config (a mirror the learner can read).
# `cat > file` (not piped to kubectl) so the Helm chart's Go-template YAML is
# written verbatim, not applied.
REPO=/root/polyphone-config
mkdir -p "$REPO/apps" "$REPO/charts/voicemail/templates" "$REPO/charts/message-store/templates"

# apps/ — a plain-manifest Kustomize dir the Flux `apps` Kustomization builds.
cat > "$REPO/apps/kustomization.yaml" <<'GIT_EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - dialplan.yaml
GIT_EOF

# dialplan — the GitOps-managed Deployment. Declared at 2 replicas in git;
# that number is the desired state Flux enforces. No namespace here — the
# Kustomization's targetNamespace lands it in app-services.
cat > "$REPO/apps/dialplan.yaml" <<'GIT_EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dialplan
  labels: { app: dialplan, plane: control, tier: lab }
spec:
  replicas: 2
  selector: { matchLabels: { app: dialplan } }
  template:
    metadata:
      labels: { app: dialplan, plane: control, tier: lab }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 80 }]
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
GIT_EOF

# charts/voicemail — a small Helm chart the `voicemail` HelmRelease renders.
# Same shape as the M17 chart, hosted inside the git repo so the HelmRelease
# can source it from the GitRepository (no external Helm repository needed).
cat > "$REPO/charts/voicemail/Chart.yaml" <<'GIT_EOF'
apiVersion: v2
name: voicemail
description: Polyphone voicemail service — lab chart for M18 (Flux)
type: application
version: 0.1.0
appVersion: "1.25"
GIT_EOF

cat > "$REPO/charts/voicemail/values.yaml" <<'GIT_EOF'
replicaCount: 1
image:
  repository: nginx
  tag: "1.25"
  pullPolicy: IfNotPresent
service:
  port: 80
resources:
  requests: { cpu: 25m, memory: 32Mi }
  limits:   { cpu: 100m, memory: 64Mi }
config:
  greeting: "You have reached Polyphone voicemail."
GIT_EOF

cat > "$REPO/charts/voicemail/templates/deployment.yaml" <<'GIT_EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: voicemail
  labels:
    app: voicemail
    plane: app
    tier: lab
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: voicemail
  template:
    metadata:
      labels:
        app: voicemail
        plane: app
        tier: lab
    spec:
      containers:
        - name: app
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: 80
          env:
            - name: GREETING
              value: {{ .Values.config.greeting | quote }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
GIT_EOF

cat > "$REPO/charts/voicemail/templates/service.yaml" <<'GIT_EOF'
apiVersion: v1
kind: Service
metadata:
  name: voicemail
  labels:
    app: voicemail
    plane: app
    tier: lab
spec:
  selector:
    app: voicemail
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 80
GIT_EOF

# charts/message-store — the voicemail app's backing store, rendered by its own
# `message-store` HelmRelease. voicemail's HelmRelease dependsOn this release, so
# it installs first — a real same-kind (HelmRelease -> HelmRelease) ordering.
cat > "$REPO/charts/message-store/Chart.yaml" <<'GIT_EOF'
apiVersion: v2
name: message-store
description: Polyphone voicemail message store — lab chart for M18 (Flux)
type: application
version: 0.1.0
appVersion: "1.25"
GIT_EOF

cat > "$REPO/charts/message-store/values.yaml" <<'GIT_EOF'
replicaCount: 1
image:
  repository: nginx
  tag: "1.25"
  pullPolicy: IfNotPresent
service:
  port: 80
resources:
  requests: { cpu: 25m, memory: 32Mi }
  limits:   { cpu: 100m, memory: 64Mi }
GIT_EOF

cat > "$REPO/charts/message-store/templates/deployment.yaml" <<'GIT_EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: message-store
  labels:
    app: message-store
    plane: app
    tier: lab
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: message-store
  template:
    metadata:
      labels:
        app: message-store
        plane: app
        tier: lab
    spec:
      containers:
        - name: app
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: 80
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
GIT_EOF

cat > "$REPO/charts/message-store/templates/service.yaml" <<'GIT_EOF'
apiVersion: v1
kind: Service
metadata:
  name: message-store
  labels:
    app: message-store
    plane: app
    tier: lab
spec:
  selector:
    app: message-store
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 80
GIT_EOF

# Commit the tree and push it to Gitea as branch `main` (the host has git and
# reaches Gitea on the NodePort). This is the one and only revision the repo
# starts with.
git -C "$REPO" init -q -b main 2>/dev/null || { git -C "$REPO" init -q; git -C "$REPO" checkout -q -b main; }
git -C "$REPO" -c user.email=setup@polyphone.example -c user.name=setup add -A
git -C "$REPO" -c user.email=setup@polyphone.example -c user.name=setup commit -q -m "seed polyphone-config" 2>/dev/null
git -C "$REPO" push -q "http://flux:flux-admin@localhost:30300/flux/polyphone-config.git" main 2>/dev/null

# --- 4. apply the Flux custom resources (healthy source, apps, message-store;
#     the ONLY broken thing is voicemail's dependsOn reference) ----------------
cat <<'EOF' | kubectl apply -f - >/dev/null
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: polyphone-config
  namespace: flux-system
spec:
  interval: 1m
  url: http://gitea.flux-system.svc.cluster.local:3000/flux/polyphone-config.git
  ref:
    branch: main
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps
  namespace: flux-system
spec:
  interval: 1m
  sourceRef:
    kind: GitRepository
    name: polyphone-config
  path: ./apps
  prune: true
  wait: true
  timeout: 2m
  targetNamespace: app-services
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: message-store
  namespace: flux-system
spec:
  interval: 1m
  targetNamespace: app-services
  chart:
    spec:
      chart: ./charts/message-store
      sourceRef:
        kind: GitRepository
        name: polyphone-config
  values:
    replicaCount: 1
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: voicemail
  namespace: flux-system
spec:
  interval: 1m
  targetNamespace: app-services
  chart:
    spec:
      chart: ./charts/voicemail
      sourceRef:
        kind: GitRepository
        name: polyphone-config
  dependsOn:
    # >>> breakfix-03 mutation: dependsOn names a HelmRelease that does not
    #     exist. voicemail must wait for its backing store; that release is
    #     `message-store`, but the dependency still names `message-cache` (a
    #     stale name from before the store was renamed). A HelmRelease dependsOn
    #     references other HelmReleases, and helm-controller holds the release as
    #     DependencyNotReady forever when the named one never appears — voicemail
    #     never installs, though source, `apps`, and message-store are all healthy.
    - name: message-cache             # MUTATED (baseline: message-store) — no such HelmRelease
    # <<< breakfix-03 mutation ends
  values:
    replicaCount: 2
EOF

# The source, `apps`, and `message-store` are healthy; force them ready so
# dialplan and message-store are up and the ONLY thing broken is voicemail's
# dependency reference. Don't wait on voicemail — it stays blocked on purpose.
flux reconcile kustomization apps --with-source --timeout=3m >/dev/null 2>&1
flux reconcile helmrelease message-store --timeout=3m >/dev/null 2>&1
kubectl rollout status deployment/dialplan -n app-services --timeout=120s >/dev/null 2>&1
kubectl rollout status deployment/message-store -n app-services --timeout=120s >/dev/null 2>&1
flux reconcile helmrelease voicemail --timeout=30s >/dev/null 2>&1
# <<< M18 addition ends

# ---------------------------------------------------------------------------
# Wait for the fleet to come up
# ---------------------------------------------------------------------------

kubectl wait --for=condition=Available deployment --all -A --timeout=120s >/dev/null 2>&1
# StatefulSets don't have an Available condition; wait for at least one ready pod
for ns in media signaling app-services edge; do
  kubectl wait --for=condition=Ready pod -l plane -n "$ns" --timeout=60s >/dev/null 2>&1
done

touch /tmp/.setup-complete
