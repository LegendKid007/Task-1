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
        sh 'mvn -B clean package'
      }
    }
    stage('Test') {
      steps {
        sh 'mvn test'
        junit '**/target/surefire-reports/*.xml'
      }
    }
    stage('Archive') {
      steps {
        archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
      }
    }
  }
}
