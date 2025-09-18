pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        TF_VAR_instance_type = "t3.micro"
        KEY_DIR = "/Users/komalsaiballa/Desktop"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Provision New EC2') {
            steps {
                script {
                    def keyName = "jenkins-${env.BUILD_NUMBER}"
                    def keyPath = "${env.KEY_DIR}/${keyName}.pem"
                    echo "🔑 Generating new key pair for this build..."
                    sh """
                        rm -f ${keyPath}
                        aws ec2 create-key-pair --key-name ${keyName} --query KeyMaterial --output text --region ${AWS_REGION} > ${keyPath}
                        chmod 400 ${keyPath}
                    """
                    echo "✅ Created new key pair: ${keyName}, saved at ${keyPath}"

                    sh """
                        terraform init -input=false
                        terraform apply -auto-approve -input=false -var=key_name=${keyName} -var=instance_type=${TF_VAR_instance_type}
                    """
                    def ec2_ip = sh(script: "terraform output -raw ec2_public_ip", returnStdout: true).trim()
                    writeFile file: "ec2_info.txt", text: "${keyName} ${ec2_ip} ${keyPath}"
                    echo "🌍 New EC2 created: ${keyName} (${ec2_ip})"
                }
            }
        }

        stage('Build Spring Boot App') {
            steps {
                script {
                    if (fileExists('mvnw')) {
                        echo "📦 Using Maven Wrapper"
                        sh "chmod +x mvnw"
                        sh "./mvnw clean package -DskipTests"
                    } else {
                        echo "📦 Using System Maven"
                        sh "mvn clean package -DskipTests"
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    def ec2_info = readFile("ec2_info.txt").trim().split(" ")
                    def keyName = ec2_info[0]
                    def ec2_ip = ec2_info[1]
                    def keyPath = ec2_info[2]
                    sh "chmod +x deploy.sh"
                    sh "bash deploy.sh ${ec2_ip} ${keyPath}"
                }
            }
        }

        stage('Verify App') {
            steps {
                script {
                    def ec2_info = readFile("ec2_info.txt").trim().split(" ")
                    def ec2_ip = ec2_info[1]
                    sh "curl -s http://${ec2_ip}:9091/hello"
                }
            }
        }
    }

    post {
        failure {
            echo "❌ Pipeline failed. Check logs."
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
    }
}
