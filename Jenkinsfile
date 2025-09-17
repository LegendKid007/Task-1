pipeline {
    agent any

    environment {
        EC2_USER = "ec2-user"
        EC2_KEY  = "/Users/komalsaiballa/Desktop/jenkins.pem"
    }

    stages {
        stage('Provision EC2 (if not exists)') {
            steps {
                script {
                    if (fileExists('ec2_ip.txt')) {
                        echo "✅ EC2 already provisioned, reusing existing instance..."
                        env.EC2_HOST = readFile('ec2_ip.txt').trim()
                    } else {
                        echo "🚀 Creating a new EC2 instance with Terraform..."
                        sh '''
                          terraform init
                          terraform apply -auto-approve
                          terraform output -raw ec2_public_ip > ec2_ip.txt
                        '''
                        env.EC2_HOST = readFile('ec2_ip.txt').trim()
                    }
                }
                echo "Using EC2 host: ${env.EC2_HOST}"
            }
        }

        stage('Build Spring Boot App') {
            steps {
                sh './mvnw clean package -DskipTests'
            }
        }

        stage('Deploy to EC2') {
            steps {
                sh "chmod 400 ${EC2_KEY}"
                sh "bash deploy.sh ${env.EC2_HOST}"
            }
        }
    }

    post {
        success {
            echo "✅ Build + Provision + Deploy successful!"
            echo "🌍 App is available at: http://${env.EC2_HOST}:9091/hello"
        }
        failure {
            echo "❌ Pipeline failed. Check logs."
        }
    }
}
