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

                    // Unique key based on Jenkins build number
                    def keyName = "jenkins-${env.BUILD_NUMBER}"
                    def keyPath = "/Users/komalsaiballa/Desktop/${keyName}.pem"

                    // Remove if file exists locally
                    sh "rm -f ${keyPath}"

                    // Create key pair in AWS and save PEM locally
                    sh """
                      aws ec2 create-key-pair --key-name ${keyName} \
                        --query 'KeyMaterial' --output text \
                        --region us-east-1 > ${keyPath}
                      chmod 400 ${keyPath}
                    """

                    // Save env vars for later stages
                    env.KEY_NAME = keyName
                    env.EC2_KEY  = keyPath

                    echo "✅ Created new key pair: ${env.KEY_NAME}, saved at ${env.EC2_KEY}"

                    // Run terraform with dynamic key_name
                    sh """
                      terraform init -input=false
                      terraform apply -auto-approve -input=false -var="key_name=${env.KEY_NAME}"
                      terraform output -raw ec2_public_ip > ec2_ip.txt
                    """

                    env.EC2_HOST = readFile('ec2_ip.txt').trim()
                    echo "🌍 New EC2 created: ${env.KEY_NAME} (${env.EC2_HOST})"

                    // Save EC2 info to Desktop log
                    sh """
                      echo '${env.KEY_NAME} ${env.EC2_HOST} ${env.EC2_KEY}' >> /Users/komalsaiballa/Desktop/ec2_list.txt
                    """
                }
            }
        }

        stage('Build Spring Boot App') {
            steps {
                sh './mvnw clean package -DskipTests'
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
