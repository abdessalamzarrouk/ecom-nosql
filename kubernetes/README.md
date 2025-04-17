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

