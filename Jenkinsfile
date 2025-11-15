pipeline {
    agent any
    # Hellooooooooooo

    environment {
        GITHUB_CREDS = 'github'
        DOCKERHUB_CREDS = 'DockerHub_Token'
        SSH_CREDS = 'ubuntu'
        DOCKER_IMAGE = "Robin S/nodejs-app"
    }

    stages {

        stage('Checkout') {
            steps {
                git credentialsId: "${GITHUB_CREDS}",
                    url: 'https://github.com/Robinsubbu/Capstone.git'
            }
        }

        stage('Build using Maven') {
            steps {
                sh """
                mvn clean install -DskipTests=false
                """
            }
        }

        stage('Test using Maven') {
            steps {
                sh """
                mvn test
                """
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:latest ."
                }
            }
        }

        stage('Docker Login & Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDS}", usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh """
                    echo "$PASS" | docker login -u "$USER" --password-stdin
                    docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Deploy to EC2 Over SSH') {
            steps {
                sshagent(['ubuntu']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ec2-user@<EC2_PUBLIC_IP> "
                        docker pull ${DOCKER_IMAGE}:latest &&
                        docker stop nodejs-app || true &&
                        docker rm nodejs-app || true &&
                        docker run -d --name nodejs-app -p 3000:3000 ${DOCKER_IMAGE}:latest
                    "
                    """
                }
            }
        }

        stage('Monitoring Check (Prometheus)') {
            steps {
                script {
                    echo "Checking Prometheus target for EC2 & Docker metrics..."

                    sh """
                    curl -s http://<EC2_PUBLIC_IP>:9090/api/v1/targets | jq .
                    """

                    echo "Monitoring check completed!"
                }
            }
        }

        stage('Backup Logs / Data') {
            steps {
                sshagent(['ubuntu']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@13.204.134.43 "
                        echo '#!/bin/bash
                        TIMESTAMP=\\$(date +%F-%H-%M)
                        mkdir -p /home/ec2-user/app-backups
                        docker logs nodejs-app > /home/ec2-user/app-backups/app-log-\\$TIMESTAMP.txt
                        ' > /home/ec2-user/backup.sh

                        chmod +x /home/ec2-user/backup.sh
                        (crontab -l 2>/dev/null; echo '0 */6 * * * /home/ec2-user/backup.sh') | crontab -
                    "
                    """
                }
            }
        }
    }
}
