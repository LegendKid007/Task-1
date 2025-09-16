pipeline {
    agent any

    tools {
        maven "Maven3"    // match your configured Maven installation name
        jdk "jdk17"       // match your configured JDK installation name
    }

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
                        scp -i $SSH_KEY -o StrictHostKeyChecking=no target/*.jar ec2-user@54.174.128.187:/home/ec2-user/app/hello.jar

                        ssh -i $SSH_KEY -o StrictHostKeyChecking=no ec2-user@54.174.128.187 << 'EOF'
                            pkill -f 'java -jar' || true
                            nohup java -jar /home/ec2-user/app/hello.jar > /home/ec2-user/app/app.log 2>&1 &
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
