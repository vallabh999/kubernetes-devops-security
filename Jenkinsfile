pipeline {
  agent any
  tools {
    maven 'maven3'
  }

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' //so that they can be downloaded later
            }
      }
      stage('Unit test') {
            steps {
              sh "mvn test"
            }  
    }
}
}
