#!/bin/bash

while ! kubectl get nodes 2>/dev/null | grep -q " Ready"; do
  sleep 2
done
sleep 5

# ============================================================
# CLUSTER PREREQUISITES
# Install local-path-provisioner so PVC workloads work.
# Gives us a "local-path" StorageClass (RWO only).
# ============================================================
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml 2>/dev/null
kubectl wait --for=condition=Ready pods -l app=local-path-provisioner -n local-path-storage --timeout=60s 2>/dev/null

# Install k9s
curl -sL https://github.com/derailed/k9s/releases/download/v0.32.7/k9s_Linux_amd64.tar.gz | tar xz -C /usr/local/bin k9s 2>/dev/null

# Install metrics-server (needed for kubectl top)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml 2>/dev/null
kubectl patch deployment metrics-server -n kube-system --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' 2>/dev/null

# Pre-label a worker node so nodeAffinity workloads (transcoder) schedule cleanly.
# Never the control-plane node: its control-plane label carries an EMPTY value,
# so a "field is blank" test matches it. Select by label negation instead.
WORKER=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
[ -z "$WORKER" ] && WORKER=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl label node "$WORKER" disktype=ssd --overwrite 2>/dev/null

# ============================================================
# Platform services — identical layout to the SRE Interview Lab,
# but every workload starts and stays healthy.
# ============================================================

kubectl create namespace provisioning
kubectl create secret generic database-creds \
    --from-literal=DB_HOST=postgres.internal \
    --from-literal=DB_PASSWORD=changeme \
    -n provisioning
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: account-provisioner
  namespace: provisioning
spec:
  replicas: 1
  selector:
    matchLabels:
      app: account-provisioner
  template:
    metadata:
      labels:
        app: account-provisioner
    spec:
      containers:
        - name: app
          image: nginx:1.25
          envFrom:
            - secretRef:
                name: database-creds
          ports:
            - containerPort: 80
EOF

kubectl create namespace call-analytics
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-aggregator
  namespace: call-analytics
spec:
  replicas: 1
  selector:
    matchLabels:
      app: metrics-aggregator
  template:
    metadata:
      labels:
        app: metrics-aggregator
    spec:
      containers:
        - name: app
          image: nginx:1.25
          resources:
            requests:
              cpu: 50m
              memory: 32Mi
            limits:
              cpu: 100m
              memory: 64Mi
          ports:
            - containerPort: 80
EOF

kubectl create namespace cdr-storage
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cdr-data
  namespace: cdr-storage
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cdr-writer
  namespace: cdr-storage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cdr-writer
  template:
    metadata:
      labels:
        app: cdr-writer
    spec:
      containers:
        - name: app
          image: nginx:1.25
          volumeMounts:
            - name: data
              mountPath: /data
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: cdr-data
EOF

kubectl create namespace admin-portal
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portal-ui
  namespace: admin-portal
spec:
  replicas: 2
  selector:
    matchLabels:
      app: portal-ui
  template:
    metadata:
      labels:
        app: portal-ui
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: portal-ui-svc
  namespace: admin-portal
spec:
  selector:
    app: portal-ui
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
EOF

kubectl create namespace call-routing
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: route-engine
  namespace: call-routing
spec:
  replicas: 2
  selector:
    matchLabels:
      app: route-engine
  template:
    metadata:
      labels:
        app: route-engine
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: route-engine-svc
  namespace: call-routing
spec:
  selector:
    app: route-engine
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
EOF

kubectl create namespace number-porting
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: pod-limit
  namespace: number-porting
spec:
  hard:
    pods: "5"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: port-processor
  namespace: number-porting
spec:
  replicas: 3
  selector:
    matchLabels:
      app: port-processor
  template:
    metadata:
      labels:
        app: port-processor
    spec:
      containers:
        - name: app
          image: nginx:1.25
          ports:
            - containerPort: 80
EOF

kubectl create namespace media-processing
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: transcoder
  namespace: media-processing
spec:
  replicas: 1
  selector:
    matchLabels:
      app: transcoder
  template:
    metadata:
      labels:
        app: transcoder
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: disktype
                    operator: In
                    values:
                      - ssd
      containers:
        - name: app
          image: nginx:1.25
          ports:
            - containerPort: 80
EOF

kubectl create namespace service-mesh
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consul-agent
  namespace: service-mesh
spec:
  replicas: 1
  selector:
    matchLabels:
      app: consul-agent
  template:
    metadata:
      labels:
        app: consul-agent
    spec:
      dnsPolicy: ClusterFirst
      containers:
        - name: app
          image: busybox:1.36
          ports:
            - containerPort: 80
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "Starting consul-agent..."
              echo "Resolving upstream dependencies..."
              while ! nslookup kubernetes.default.svc.cluster.local; do
                echo "DNS lookup failed, retrying in 5s..."
                sleep 5
              done
              echo "Dependencies resolved, starting service..."
              httpd -f -p 80
EOF

kubectl wait --for=condition=Available deployment --all -A --timeout=180s 2>/dev/null

touch /tmp/.setup-complete
