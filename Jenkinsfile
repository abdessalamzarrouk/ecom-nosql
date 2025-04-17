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
        stage('Test Docker Access') {
          steps {
            sh 'docker ps'
          }
        }
        stage('Docker Build') {
          steps {
            sh 'docker compose up --build -d' 
          }
        }
        
        stage('Deployement stage') {
            steps {
                sh 'echo "Microservices deployed succesfully"'
            }
        }
    }
}
