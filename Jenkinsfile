pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/LegendKid007/Task-1.git'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn -B clean package -DskipTests'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Deploy') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', 
                                                  keyFileVariable: 'SSH_KEY')]) {
                    sh '''
                        echo ">>> Deploying JAR to EC2..."
                        # Copy JAR to EC2
                        scp -i $SSH_KEY -o StrictHostKeyChecking=no target/*.jar ec2-user@54.174.128.187:/home/ec2-user/app/hello.jar

                        # Restart the application on EC2
                        ssh -i $SSH_KEY -o StrictHostKeyChecking=no ec2-user@54.174.128.187 << 'EOF'
                            echo ">>> Stopping old app (if running)..."
                            pkill -f 'java -jar' || true

                            echo ">>> Starting new app..."
                            nohup java -jar /home/ec2-user/app/hello.jar > /home/ec2-user/app/app.log 2>&1 &

                            echo ">>> Deployment complete. App is running."
                        EOF
                    '''
                }
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
    }
}
