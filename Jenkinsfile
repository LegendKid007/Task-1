pipeline {
    agent any

    environment {
        EC2_USER = "ec2-user"
        EC2_KEY  = "/Users/komalsaiballa/Desktop/jenkins.pem"
    }

    stages {
        stage('Provision New EC2') {
            steps {
                script {
                    echo "🚀 Creating a fresh EC2 instance with Terraform..."
                    sh '''
                      export PATH=/opt/homebrew/bin:$PATH   # Ensure Jenkins sees terraform
                      rm -f ec2_ip.txt
                      terraform init -input=false
                      terraform apply -auto-approve -input=false
                      terraform output -raw ec2_public_ip > ec2_ip.txt
                    '''
                    env.EC2_HOST = readFile('ec2_ip.txt').trim()
                    echo "✅ New EC2 created: ${env.EC2_HOST}"
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
                sh "chmod 400 ${EC2_KEY}"
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
            echo "🌍 App is available at: http://${env.EC2_HOST}:9091/hello"
        }
        failure {
            echo "❌ Pipeline failed. Check logs."
        }
    }
}
