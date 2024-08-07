pipeline {
  agent {
    kubernetes {
      yaml '''
        apiVersion: v1
        kind: Pod
        metadata:
          name: jenkins-agent
        spec:
          nodeName: 'ip-172-31-4-194.ap-south-1.compute.internal'
          containers:
          - name: maven
            image: maven:alpine
            command:
            - cat
            tty: true
          - name: docker
            image: docker:latest
            command:
            - cat
            tty: true
            volumeMounts:
            - name: docker-sock
              mountPath: /var/run/docker.sock
          volumes:
          - name: docker-sock
            hostPath:
              path: /var/run/docker.sock
        '''
    }
  }
  tools {
    maven 'maven3'
  }

  stages {
      stage('Build Artifact') {
            steps {
              container ('maven'){
                sh "mvn clean package -DskipTests=true"
                archive 'target/*.jar' //so that they can be downloaded later
              }
            }
      }
      stage('Unit test') {
            steps {
                container ('maven'){
                sh "mvn test"
                }  
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
        container ('docker'){
          withDockerRegistry([credentialsId: "docker-hub", url: ""]){
            sh 'printenv'
            sh 'docker build -t valabh4/numeric:"GIT_COMMIT" .'
            sh 'docker push vallabh4/numeric:"GIT_COMMIT"'
            }
        }
      }
    }
}
}
