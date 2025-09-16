pipeline {
    agent any

    tools {
        maven 'Maven3'
        jdk 'jdk17'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/LegendKid007/Task-1.git'
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
                junit '**/target/surefire-reports/*.xml'
            }
        }

        stage('Deploy') {
            steps {
                // Make sure deploy.sh is executable
                sh 'chmod +x deploy.sh'
                // Run deploy.sh (script already knows about the key and EC2)
                sh './deploy.sh'
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
    }
}
