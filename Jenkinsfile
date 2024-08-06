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
        post {
          always {
            junit 'target/surefire-reports/*.xml'
            jacoco execPattern: 'target/jacoco.exe'
          }
        }
    }
    stage('Docker Build and Push'){
      steps{
        withDockerRegistry([credentialsId: "docker-hub", url: ""]){
        sh 'printenv'
        sh 'docker build -t valabh4/numeric:"GIT_COMMIT" .'
        sh 'docker push vallabh4/numeric:"GIT_COMMIT"'
      }
      }
    }
}
}
