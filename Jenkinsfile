pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
        TF_VAR_instance_type = "t3.micro"
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
                    echo "🔑 Using Terraform to create key + EC2"
                    sh """
                        terraform init -input=false
                        terraform apply -auto-approve -input=false -var=key_name=${keyName} -var=instance_type=${TF_VAR_instance_type}
                    """
                    def ec2_ip = sh(script: "terraform output -raw ec2_public_ip", returnStdout: true).trim()
                    def pem_file = sh(script: "terraform output -raw pem_file", returnStdout: true).trim()
                    writeFile file: "ec2_info.txt", text: "${keyName} ${ec2_ip} ${pem_file}"
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
                    def ec2_ip = ec2_info[1]
                    def pem_file = ec2_info[2]
                    sh "chmod +x deploy.sh"
                    sh "bash deploy.sh ${ec2_ip} ${pem_file}"
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
