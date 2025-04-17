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
            sh './pythonscript/insert_product.sh'
          }
        }
        stage('Test Docker Access') {
          steps {
            sh 'docker ps'
          }
        }
        stage('Build Services') {
            steps {
                sh 'docker compose up --build -d'
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl apply -f kubernetes/'
            }
        }
    }
}
