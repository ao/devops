# Cert-manager.io

## Download and Install cert-manager
```
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.yaml
```

## Deploy ingress controller
```
kubectl create ns ingress-nginx
kubectl -n ingress-nginx apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.41.2/deploy/static/provider/cloud/deploy.yaml
kubectl -n ingress-nginx get pods
```

## Create ClusterIssuer
```
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-cluster-issuer
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@email.com
    privateKeySecretRef:
      name: letsencrypt-cluster-issuer-key
    solvers:
      - http01:
          ingress:
            class: nginx
EOF
```

## Check the issuer
```
kubectl describe clusterissuer letsencrypt-cluster-issuer
```

## Deploy a pod that uses SSL
```
cat <<EOF | kubectl apply -f -
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-deploy
  labels:
    app: example-app
    test: test
  annotations:
    fluxcd.io/tag.example-app: semver:~1.0
    fluxcd.io/automated: 'true'
spec:
  selector:
    matchLabels:
      app: example-app
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: example-app
    spec:
      containers:
        - name: example-app
          image: aimvector/python:1.0.4
          imagePullPolicy: Always
          ports:
            - containerPort: 5000
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "256Mi"
              cpu: "500m"
      tolerations:
        - key: "cattle.io/os"
          value: "linux"
          effect: "NoSchedule"
EOF
```

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: example-service
  labels:
    app: example-app
spec:
  type: LoadBalancer
  selector:
    app: example-app
  ports:
    - protocol: TCP
      name: http
      port: 80
      targetPort: 5000
EOF
```

```
kubectl get pods
```

## Deploy an ingress route
```
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: "nginx"
  name: frontend
  namespace: apps
spec:
  tls:
    - hosts:
        - tls-test.dev.ao.ms
      secretName: frontend-tls
  rules:
    - host: tls-test.dev.ao.ms
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80
EOF
```

## Issue Certificate
```
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: frontend
  namespace: apps
spec:
  dnsNames:
    - tls-test.dev.ao.ms
  secretName: frontend-tls
  issuerRef:
    name: letsencrypt-cluster-issuer
    kind: ClusterIssuer
EOF
```

## Informational

### check the cert has been issued
```
kubectl describe certificate example-app
```
 
### TLS created as a secret
```
kubectl get secrets
```
