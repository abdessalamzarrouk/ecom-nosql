pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/abdessalamzarrouk/ecom-nosql.git'
            }
        }
        triggers{
            pollSCM 'H/5 * * * *'
        }
        
        stage('Build Services') {
            steps {
                sh 'docker compose up --build'
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl apply -f kubernetes/'
            }
        }
    }
}
