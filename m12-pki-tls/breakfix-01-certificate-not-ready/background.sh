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
# M12 additions — cert-manager, an internal CA, and an mTLS workload pair.
# cert-manager is the controller that turns a declarative Certificate object into
# a real signed key pair in a kubernetes.io/tls Secret. We install it, mint a
# self-signed internal CA, and issue a server + client identity from that CA so a
# workload-to-workload call (config-client -> config-api) runs over mutual TLS.
# Nothing here is broken — this is the healthy reference the tour reads.
# ===========================================================================

# Install cert-manager (its CRDs + controller + webhook + cainjector), pinned to a
# known-good release. The webhook validates/defaults every Issuer and Certificate,
# so nothing PKI-related can be created until it is serving — we wait for it below.
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml >/dev/null 2>&1
kubectl -n cert-manager wait --for=condition=Available deployment --all --timeout=180s >/dev/null 2>&1

# The bootstrap issuer: a SelfSigned ClusterIssuer that can mint a self-signed root.
# Retry until it applies — even after the webhook Deployment is Available, the
# cainjector needs a moment to write the webhook's caBundle, and until it does the
# apply is rejected with "no endpoints available for service cert-manager-webhook".
for i in $(seq 1 30); do
  kubectl apply -f - >/dev/null 2>&1 <<'EOF' && break
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata: { name: selfsigned-bootstrap, labels: { plane: platform, tier: lab } }
spec:
  selfSigned: {}
EOF
  sleep 3
done

# The internal CA: a self-signed root minted by the bootstrap issuer, stored in
# Secret polyphone-internal-ca. The CA ClusterIssuer reads its signing key from the
# cluster resource namespace (cert-manager), so the CA Certificate lives there too.
# A second, independent CA (polyphone-legacy-ca) is minted alongside — it is the
# wrong trust anchor breakfix-03 uses; here it just sits unused.
kubectl apply -f - >/dev/null 2>&1 <<'EOF'
apiVersion: cert-manager.io/v1
kind: Certificate
metadata: { name: polyphone-internal-ca, namespace: cert-manager, labels: { plane: platform, tier: lab } }
spec:
  isCA: true
  commonName: polyphone-internal-ca
  secretName: polyphone-internal-ca
  duration: 87600h
  privateKey: { algorithm: ECDSA, size: 256 }
  issuerRef: { name: selfsigned-bootstrap, kind: ClusterIssuer, group: cert-manager.io }
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata: { name: polyphone-legacy-ca, namespace: cert-manager, labels: { plane: platform, tier: lab } }
spec:
  isCA: true
  commonName: polyphone-legacy-ca
  secretName: polyphone-legacy-ca
  duration: 87600h
  privateKey: { algorithm: ECDSA, size: 256 }
  issuerRef: { name: selfsigned-bootstrap, kind: ClusterIssuer, group: cert-manager.io }
EOF
kubectl wait --for=condition=Ready certificate/polyphone-internal-ca -n cert-manager --timeout=90s >/dev/null 2>&1
kubectl wait --for=condition=Ready certificate/polyphone-legacy-ca   -n cert-manager --timeout=90s >/dev/null 2>&1

# The internal CA issuer — signs leaf certificates using the CA key/cert above.
kubectl apply -f - >/dev/null 2>&1 <<'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata: { name: polyphone-ca, labels: { plane: platform, tier: lab } }
spec:
  ca:
    secretName: polyphone-internal-ca
EOF

# Leaf identities from the internal CA: a server (config-api, media) and a client
# (config-client, app-services). Each Certificate produces a kubernetes.io/tls
# Secret holding tls.crt / tls.key / ca.crt.
kubectl apply -f - >/dev/null 2>&1 <<'EOF'
apiVersion: cert-manager.io/v1
kind: Certificate
metadata: { name: config-api-tls, namespace: media, labels: { app: config-api, plane: media, tier: lab } }
spec:
  secretName: config-api-tls
  duration: 2160h
  dnsNames:
    - config-api.media.svc.cluster.local
    - config-api.media.svc
    - config-api
  # >>> breakfix-01 mutation: point this leaf's issuerRef at an issuer that does not exist.
  #     cert-manager can't resolve it, so config-api-tls never becomes Ready, the Secret
  #     config-api-tls is never created, and the config-api Pod that mounts it stays stuck
  #     ContainerCreating (FailedMount: secret "config-api-tls" not found). The fix is to
  #     repoint issuerRef at the real internal-CA issuer (polyphone-ca).
  issuerRef: { name: polyphone-ca-typo, kind: ClusterIssuer, group: cert-manager.io }   # MUTATED (baseline: polyphone-ca)
  # <<< breakfix-01 mutation ends
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata: { name: config-client-tls, namespace: app-services, labels: { app: config-client, plane: app, tier: lab } }
spec:
  secretName: config-client-tls
  commonName: config-client
  usages: [client auth, digital signature, key encipherment]
  issuerRef: { name: polyphone-ca, kind: ClusterIssuer, group: cert-manager.io }
EOF
kubectl wait --for=condition=Ready certificate/config-api-tls    -n media        --timeout=20s >/dev/null 2>&1   # breakfix-01: trimmed — this cert intentionally never issues
kubectl wait --for=condition=Ready certificate/config-client-tls -n app-services --timeout=90s >/dev/null 2>&1

# Trust bundles the client mounts to verify the server. internal-ca-bundle is the
# correct root; legacy-ca-bundle is the decoy for breakfix-03. Populated by copying
# each CA's public cert (ca.crt) out of its cert-manager Secret.
kubectl get secret polyphone-internal-ca -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/internal-ca.crt 2>/dev/null
kubectl get secret polyphone-legacy-ca   -n cert-manager -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/legacy-ca.crt   2>/dev/null
kubectl create secret generic internal-ca-bundle -n app-services --from-file=ca.crt=/tmp/internal-ca.crt --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1
kubectl create secret generic legacy-ca-bundle   -n app-services --from-file=ca.crt=/tmp/legacy-ca.crt   --dry-run=client -o yaml | kubectl apply -f - >/dev/null 2>&1

# The server: config-api (media) — nginx serving HTTPS on 8443 and requiring a
# client certificate signed by the internal CA (mutual TLS). Its serving cert comes
# from Secret config-api-tls; the CA it verifies clients against is that Secret's ca.crt.
kubectl apply -f - >/dev/null 2>&1 <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata: { name: config-api-nginx, namespace: media, labels: { app: config-api, plane: media, tier: lab } }
data:
  config-api.conf: |
    server {
      listen 8443 ssl;
      server_name config-api.media.svc.cluster.local;
      ssl_certificate     /etc/nginx/tls/tls.crt;
      ssl_certificate_key /etc/nginx/tls/tls.key;
      ssl_client_certificate /etc/nginx/tls/ca.crt;
      ssl_verify_client   on;
      location / {
        default_type text/plain;
        return 200 "config-api: mTLS OK, client=$ssl_client_s_dn\n";
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: config-api, namespace: media, labels: { app: config-api, plane: media, tier: lab } }
spec:
  replicas: 1
  selector: { matchLabels: { app: config-api } }
  template:
    metadata: { labels: { app: config-api, plane: media, tier: lab } }
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports: [{ containerPort: 8443, name: https }]
          volumeMounts:
            - { name: tls,  mountPath: /etc/nginx/tls, readOnly: true }
            - { name: conf, mountPath: /etc/nginx/conf.d }
          resources:
            requests: { cpu: 25m, memory: 32Mi }
            limits:   { cpu: 100m, memory: 64Mi }
      volumes:
        - name: tls
          secret: { secretName: config-api-tls }
        - name: conf
          configMap: { name: config-api-nginx }
---
apiVersion: v1
kind: Service
metadata: { name: config-api, namespace: media, labels: { app: config-api, plane: media, tier: lab } }
spec:
  selector: { app: config-api }
  ports: [{ port: 443, targetPort: 8443, name: https }]
EOF

# The client: config-client (app-services) — long-lived so you can exec into it and
# call config-api over mTLS. Mounts its own identity (config-client-tls) at
# /etc/tls/id and the trust bundle (internal-ca-bundle) at /etc/tls/trust.
kubectl apply -f - >/dev/null 2>&1 <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: { name: config-client, namespace: app-services, labels: { app: config-client, plane: app, tier: lab } }
spec:
  replicas: 1
  selector: { matchLabels: { app: config-client } }
  template:
    metadata: { labels: { app: config-client, plane: app, tier: lab } }
    spec:
      containers:
        - name: client
          image: curlimages/curl:8.11.1
          command: ["/bin/sh", "-c", "while true; do sleep 3600; done"]
          volumeMounts:
            - { name: id,    mountPath: /etc/tls/id,    readOnly: true }
            - { name: trust, mountPath: /etc/tls/trust, readOnly: true }
          resources:
            requests: { cpu: 10m, memory: 16Mi }
            limits:   { cpu: 50m, memory: 32Mi }
      volumes:
        - name: id
          secret: { secretName: config-client-tls }
        - name: trust
          secret: { secretName: internal-ca-bundle }
EOF

kubectl rollout status deployment/config-api    -n media        --timeout=20s >/dev/null 2>&1   # breakfix-01: trimmed — config-api stays ContainerCreating (its cert Secret is never created)
kubectl rollout status deployment/config-client -n app-services --timeout=90s >/dev/null 2>&1

touch /tmp/.setup-complete
