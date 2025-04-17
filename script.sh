#!/bin/bash

# Script pour générer les fichiers Kubernetes et le Jenkinsfile pour le projet ecom-nosql
# Auteur: Claude
# Date: 17 Avril 2025

set -e  # Arrêter le script en cas d'erreur

echo "========================================================"
echo "Génération des fichiers Kubernetes pour ecom-nosql"
echo "========================================================"

# Création du dossier kubernetes s'il n'existe pas
mkdir -p kubernetes

# Fonction pour générer un fichier
generate_file() {
    local filename=$1
    local content=$2
    
    echo "Création de $filename..."
    echo "$content" > "$filename"
    chmod 644 "$filename"
    echo "✅ $filename créé avec succès"
}

# Génération de deployments.yaml
cat > kubernetes/deployments.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
    spec:
      containers:
      - name: product-service
        image: ${DOCKER_REGISTRY}/product-service:${VERSION}
        ports:
        - containerPort: 8080
        env:
        - name: NODE_ENV
          value: "production"
        - name: CASSANDRA_HOST
          value: "cassandra-service"
        - name: CASSANDRA_PORT
          value: "9042"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cart-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cart-service
  template:
    metadata:
      labels:
        app: cart-service
    spec:
      containers:
      - name: cart-service
        image: ${DOCKER_REGISTRY}/cart-service:${VERSION}
        ports:
        - containerPort: 8083
        env:
        - name: REDIS_HOST
          value: "redis-service"
        - name: REDIS_PORT
          value: "6379"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
      - name: order-service
        image: ${DOCKER_REGISTRY}/order-service:${VERSION}
        ports:
        - containerPort: 8082
        env:
        - name: POSTGRES_HOST
          value: "postgres-service"
        - name: POSTGRES_PORT
          value: "5432"
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: POSTGRES_DB
          value: "order"
        - name: PORT
          value: "8082"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-gateway
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-gateway
  template:
    metadata:
      labels:
        app: nginx-gateway
    spec:
      containers:
      - name: nginx-gateway
        image: ${DOCKER_REGISTRY}/nginx-gateway:${VERSION}
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "300m"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cassandra
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cassandra
  template:
    metadata:
      labels:
        app: cassandra
    spec:
      containers:
      - name: cassandra
        image: cassandra:latest
        ports:
        - containerPort: 9042
        env:
        - name: CASSANDRA_CLUSTER_NAME
          value: "e-commerce_cluster"
        - name: CASSANDRA_DC
          value: "dc1"
        - name: CASSANDRA_RACK
          value: "rack1"
        volumeMounts:
        - name: cassandra-data
          mountPath: /var/lib/cassandra
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
      volumes:
      - name: cassandra-data
        persistentVolumeClaim:
          claimName: cassandra-pvc
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "300m"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:latest
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: POSTGRES_DB
          value: "order"
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
        - name: postgres-init
          mountPath: /docker-entrypoint-initdb.d
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: postgres-data
        persistentVolumeClaim:
          claimName: postgres-pvc
      - name: postgres-init
        configMap:
          name: postgres-init-scripts
EOF
echo "✅ kubernetes/deployments.yaml créé avec succès"

# Génération de services.yaml
cat > kubernetes/services.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: product-service
spec:
  selector:
    app: product-service
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: cart-service
spec:
  selector:
    app: cart-service
  ports:
  - port: 8083
    targetPort: 8083
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
spec:
  selector:
    app: order-service
  ports:
  - port: 8082
    targetPort: 8082
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-gateway
spec:
  selector:
    app: nginx-gateway
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort
---
apiVersion: v1
kind: Service
metadata:
  name: cassandra-service
spec:
  selector:
    app: cassandra
  ports:
  - port: 9042
    targetPort: 9042
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
EOF
echo "✅ kubernetes/services.yaml créé avec succès"

# Génération de configmap.yaml
cat > kubernetes/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  NODE_ENV: "production"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: cassandra-config
data:
  CASSANDRA_CLUSTER_NAME: "e-commerce_cluster"
  CASSANDRA_DC: "dc1"
  CASSANDRA_RACK: "rack1"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-init-scripts
data:
  order.sql: |
    -- Ce contenu sera remplacé par le contenu réel de votre fichier order.sql
    CREATE TABLE IF NOT EXISTS orders (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL,
      total_amount DECIMAL(10, 2) NOT NULL,
      status VARCHAR(50) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS order_items (
      id SERIAL PRIMARY KEY,
      order_id INTEGER REFERENCES orders(id),
      product_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL,
      price DECIMAL(10, 2) NOT NULL
    );
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log warn;
    pid /var/run/nginx.pid;

    events {
      worker_connections 1024;
    }

    http {
      include /etc/nginx/mime.types;
      default_type application/octet-stream;
      sendfile on;
      keepalive_timeout 65;

      server {
        listen 80;
        server_name localhost;

        location /api/product {
          proxy_pass http://product-service:8080;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
        }

        location /auth {
          proxy_pass http://product-service:8080;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
        }

        location /cart {
          proxy_pass http://cart-service:8083;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
        }

        location /api/orders {
          proxy_pass http://order-service:8082;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
        }

        location /graphql {
          proxy_pass http://product-service:8080;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
        }
      }
    }
EOF
echo "✅ kubernetes/configmap.yaml créé avec succès"

# Génération de pvc.yaml
cat > kubernetes/pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cassandra-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: standard
EOF
echo "✅ kubernetes/pvc.yaml créé avec succès"

# Génération de secrets.yaml
cat > kubernetes/secrets.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
data:
  # Les valeurs sont encodées en base64
  # Pour postgres/142536:
  username: cG9zdGdyZXM=      # postgres en base64
  password: MTQyNTM2          # 142536 en base64
EOF
echo "✅ kubernetes/secrets.yaml créé avec succès"

# Génération de ingress.yaml
cat > kubernetes/ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ecom-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: ecom.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-gateway
            port:
              number: 80
EOF
echo "✅ kubernetes/ingress.yaml créé avec succès"

# Génération du README.md
cat > kubernetes/README.md << 'EOF'
# Kubernetes Deployment pour l'Architecture Microservices E-commerce

Ce dossier contient les fichiers de configuration Kubernetes nécessaires pour déployer l'architecture microservice de l'application e-commerce (ecom-nosql).

## Structure des fichiers

- deployments.yaml : Configurations des déploiements pour tous les microservices (product, cart, order) et leurs bases de données (Cassandra, Redis, PostgreSQL)
- services.yaml : Définitions des services Kubernetes pour exposer les microservices
- configmap.yaml : Configurations partagées pour les applications et les bases de données
- secrets.yaml : Informations sensibles comme les identifiants de base de données
- pvc.yaml : Persistent Volume Claims pour les données persistantes (Cassandra, PostgreSQL)
- ingress.yaml : Configuration de l'ingress pour exposer l'API Gateway (NGINX)

## Prérequis

- Un cluster Kubernetes fonctionnel
- kubectl configuré pour communiquer avec votre cluster
- Un registry Docker accessible
- Ingress Controller installé sur votre cluster (comme NGINX Ingress Controller)

## Déploiement manuel

Pour déployer manuellement l'application, exécutez les commandes suivantes:

bash
# Créer les secrets pour les informations sensibles
kubectl apply -f kubernetes/secrets.yaml

# Créer les configmaps pour les configurations
kubectl apply -f kubernetes/configmap.yaml

# Créer les volumes persistants
kubectl apply -f kubernetes/pvc.yaml

# Déployer les microservices et leurs bases de données
kubectl apply -f kubernetes/deployments.yaml

# Créer les services pour exposer les microservices
kubectl apply -f kubernetes/services.yaml

# Configurer l'ingress pour l'accès externe
kubectl apply -f kubernetes/ingress.yaml


## Architecture des microservices

L'application est composée des services suivants:

1. *Product Service* : Gère les produits et les utilisateurs (Node.js + Cassandra)
   - Ports: 8080
   - Endpoints: /api/product, /auth, /graphql

2. *Cart Service* : Gère les paniers des utilisateurs (Node.js + Redis)
   - Ports: 8083
   - Endpoints: /cart

3. *Order Service* : Gère les commandes (Node.js + PostgreSQL)
   - Ports: 8082
   - Endpoints: /api/orders

4. *NGINX Gateway* : Passerelle API pour router les requêtes vers les services appropriés
   - Ports: 80
   - Routage selon les endpoints

## Intégration avec Jenkins

Le pipeline Jenkins défini dans le fichier Jenkinsfile automatise le processus de build, tests, création d'images Docker et déploiement sur Kubernetes. Assurez-vous de configurer les variables d'environnement et les credentials Jenkins appropriés :

1. DOCKER_REGISTRY : URL de votre registry Docker
2. kubeconfig : Credential Jenkins contenant la configuration Kubernetes
3. docker-registry-token : Token d'authentification pour le registry Docker

## Variables à personnaliser

Avant le déploiement, assurez-vous de remplacer les valeurs suivantes dans les fichiers de configuration :

- Dans secrets.yaml : Remplacez les credentials encodés en base64 si nécessaire
- Dans configmap.yaml : Ajustez les configurations selon vos besoins
- Dans deployments.yaml : Remplacez ${DOCKER_REGISTRY} et ${VERSION} par vos valeurs
- Dans ingress.yaml : Remplacez ecom.example.com par votre nom de domaine

## Haute disponibilité et scaling

- Les microservices principaux sont configurés avec 2 replicas pour assurer la haute disponibilité
- Vous pouvez ajuster le nombre de replicas en fonction de vos besoins de scaling
- Pour les bases de données, considérez d'utiliser des StatefulSets pour des déploiements plus robustes

## Surveillance et logging

Pour surveiller vos déploiements:

bash
# Vérifier l'état des pods
kubectl get pods

# Vérifier l'état des services
kubectl get services

# Vérifier l'état de l'ingress
kubectl get ingress

# Consulter les logs d'un pod spécifique
kubectl logs <nom-du-pod>

EOF
echo "✅ kubernetes/README.md créé avec succès"

# Génération du Jenkinsfile
cat > Jenkinsfile << 'EOF'
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'your-docker-registry'
        VERSION = "${env.BUILD_NUMBER}"
        KUBECONFIG = credentials('kubeconfig')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Microservices') {
            parallel {
                stage('Build Product Service') {
                    steps {
                        dir('product') {
                            sh 'npm install'
                            sh 'npm run build'
                        }
                    }
                }
                stage('Build Cart Service') {
                    steps {
                        dir('cart') {
                            sh 'npm install'
                            sh 'npm run build'
                        }
                    }
                }
                stage('Build Order Service') {
                    steps {
                        dir('order') {
                            sh 'npm install'
                            sh 'npm run build'
                        }
                    }
                }
            }
        }
        
        stage('Run Tests') {
            parallel {
                stage('Test Product Service') {
                    steps {
                        dir('product') {
                            sh 'npm test'
                        }
                    }
                }
                stage('Test Cart Service') {
                    steps {
                        dir('cart') {
                            sh 'npm test'
                        }
                    }
                }
                stage('Test Order Service') {
                    steps {
                        dir('order') {
                            sh 'npm test'
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Images') {
            parallel {
                stage('Docker Product Service') {
                    steps {
                        dir('product') {
                            sh "docker build -t ${DOCKER_REGISTRY}/product-service:${VERSION} ."
                        }
                    }
                }
                stage('Docker Cart Service') {
                    steps {
                        dir('cart') {
                            sh "docker build -t ${DOCKER_REGISTRY}/cart-service:${VERSION} ."
                        }
                    }
                }
                stage('Docker Order Service') {
                    steps {
                        dir('order') {
                            sh "docker build -t ${DOCKER_REGISTRY}/order-service:${VERSION} ."
                        }
                    }
                }
                stage('Docker NGINX Gateway') {
                    steps {
                        dir('nginx') {
                            sh "docker build -t ${DOCKER_REGISTRY}/nginx-gateway:${VERSION} ."
                        }
                    }
                }
            }
        }
        
        stage('Push Docker Images') {
            steps {
                withCredentials([string(credentialsId: 'docker-registry-token', variable: 'DOCKER_TOKEN')]) {
                    sh "docker login ${DOCKER_REGISTRY} -u jenkins -p ${DOCKER_TOKEN}"
                    sh "docker push ${DOCKER_REGISTRY}/product-service:${VERSION}"
                    sh "docker push ${DOCKER_REGISTRY}/cart-service:${VERSION}"
                    sh "docker push ${DOCKER_REGISTRY}/order-service:${VERSION}"
                    sh "docker push ${DOCKER_REGISTRY}/nginx-gateway:${VERSION}"
                }
            }
        }
        
        stage('Update Kubernetes Manifest') {
            steps {
                sh "sed -i 's|\\\${DOCKER_REGISTRY}|${DOCKER_REGISTRY}|g' kubernetes/deployments.yaml"
                sh "sed -i 's|\\\${VERSION}|${VERSION}|g' kubernetes/deployments.yaml"
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                sh "kubectl apply -f kubernetes/secrets.yaml"
                sh "kubectl apply -f kubernetes/configmap.yaml"
                sh "kubectl apply -f kubernetes/pvc.yaml"
                sh "kubectl apply -f kubernetes/deployments.yaml"
                sh "kubectl apply -f kubernetes/services.yaml"
                sh "kubectl apply -f kubernetes/ingress.yaml"
            }
        }
        
        stage('Verify Deployment') {
            steps {
                sh "kubectl get pods"
                sh "kubectl get services"
            }
        }
    }
    
    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
            
            // Notifications can be added here
            // mail to: 'team@example.com',
            //     subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
            //     body: "Something is wrong with ${env.BUILD_URL}"
        }
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
    }
}
EOF
echo "✅ Jenkinsfile créé avec succès"

# Rendre le script exécutable
chmod +x generate-k8s-files.sh

echo "========================================================"
echo "✅ Génération des fichiers terminée avec succès !"
echo "========================================================"
echo "Les fichiers suivants ont été créés :"
echo "- kubernetes/deployments.yaml"
echo "- kubernetes/services.yaml"
echo "- kubernetes/configmap.yaml"
echo "- kubernetes/pvc.yaml"
echo "- kubernetes/secrets.yaml"
echo "- kubernetes/ingress.yaml"
echo "- kubernetes/README.md"
echo "- Jenkinsfile"
echo ""
echo "Vous pouvez maintenant déployer votre application en utilisant kubectl ou Jenkins."
echo "========================================================"
