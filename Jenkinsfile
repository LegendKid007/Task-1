pipeline {
    agent any

    environment {
        EC2_USER = "ec2-user"
        PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    }

    stages {
        stage('Provision New EC2') {
            steps {
                script {
                    echo "🔑 Generating new key pair for this build..."

                    def keyName = "jenkins-${env.BUILD_NUMBER}"
                    def keyPath = "/Users/komalsaiballa/Desktop/${keyName}.pem"

                    sh "rm -f ${keyPath}"

                    sh """
                      aws ec2 create-key-pair --key-name ${keyName} \
                        --query 'KeyMaterial' --output text \
                        --region us-east-1 > ${keyPath}
                      chmod 400 ${keyPath}
                    """

                    env.KEY_NAME = keyName
                    env.EC2_KEY  = keyPath

                    echo "✅ Created new key pair: ${env.KEY_NAME}, saved at ${env.EC2_KEY}"

                    sh """
                      terraform init -input=false
                      terraform apply -auto-approve -input=false \
                        -var="key_name=${env.KEY_NAME}" \
                        -var="instance_type=t3.micro"
                      terraform output -raw ec2_public_ip > ec2_ip.txt
                    """

                    env.EC2_HOST = readFile('ec2_ip.txt').trim()
                    echo "🌍 New EC2 created: ${env.KEY_NAME} (${env.EC2_HOST})"

                    sh """
                      echo '${env.KEY_NAME} ${env.EC2_HOST} ${env.EC2_KEY}' >> /Users/komalsaiballa/Desktop/ec2_list.txt
                    """
                }
            }
        }

        stage('Build Spring Boot App') {
            steps {
                script {
                    if (fileExists('mvnw')) {
                        echo "📦 Using Maven Wrapper"
                        sh 'chmod +x mvnw'
                        sh './mvnw clean package -DskipTests'
                    } else {
                        echo "📦 Maven wrapper not found, using system Maven"
                        sh 'mvn clean package -DskipTests'
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sh "chmod 400 ${env.EC2_KEY}"
                sh "bash deploy.sh ${env.EC2_HOST}"
            }
        }

        stage('Verify App') {
            steps {
                sh "sleep 20 && curl -f http://${env.EC2_HOST}:9091/hello"
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline complete!"
            echo "🌍 App is running on EC2: ${env.KEY_NAME} (${env.EC2_HOST})"
        }
        failure {
            echo "❌ Pipeline failed. Check logs."
        }
    }
}
