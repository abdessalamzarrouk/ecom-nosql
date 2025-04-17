pipeline {
    agent any
            triggers{
            pollSCM 'H/5 * * * *'
        }
        
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/abdessalamzarrouk/ecom-nosql.git'
            }
        }
        stage('data base insert ') {
          steps {
            sh 'rm kubernetes/configmap.yaml \
                kubernetes/deployments.yaml \
                kubernetes/ingress.yaml \
                kubernetes/pvc.yaml \
                kubernetes/secrets.yaml \
                kubernetes/README.md \
                kubernetes/services.yaml'
          }
        }
        stage('Test Docker Access') {
          steps {
            sh 'docker ps'
          }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl apply -f kubernetes/ --validate=false'
            }
        }
    }
}
