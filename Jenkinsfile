pipeline {
    agent any

    environment {
        GITHUB_REPO = 'https://github.com/shubhra006/TaskFlow-devops.git'
        APP_DIR     = '/home/ubuntu/TaskFlow-devops'
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: "${GITHUB_REPO}"
            }
        }

        stage('Verify Tools') {
            steps {
                sh 'docker --version'
                sh 'docker compose version'
            }
        }

        stage('Build') {
            steps {
                sh 'docker compose build --no-cache'
            }
        }

        stage('Deploy') {
            steps {
                sh 'bash ${APP_DIR}/scripts/deploy.sh'
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    sleep 10
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health)
                    if [ "$STATUS" != "200" ]; then
                        echo "Health check failed: HTTP $STATUS"
                        docker compose logs --tail=20
                        exit 1
                    fi
                    echo "Health check passed."
                '''
            }
        }
    }

    post {
        success { echo 'Pipeline complete — app is deployed and healthy.' }
        failure { echo 'Pipeline failed — check the stage logs above.' }
    }
}