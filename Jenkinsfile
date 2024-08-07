pipeline {
  agent {
    kubernetes {
      yaml '''
        apiVersion: v1
        kind: Pod
        metadata:
          name: jenkins-agent
          namespace: jenkins
        spec:
          nodeName: 'ip-172-31-4-194.ap-south-1.compute.internal'
          containers:
          - name: maven
            image: maven:alpine
            command:
            - cat
            tty: true
          - name: docker
            image: docker:dind
            securityContext:
              privileged: true
            command:
            - dockerd
            args:
            - --host=tcp://127.0.0.1:2375
            - --host=unix:///var/run/docker.sock
            volumeMounts:
            - name: cache
              mountPath: "/root"
              readOnly: false
          volumes:
          - name: cache
            persistentVolumeClaim:
              claimName: jenkins
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
            sh 'docker build -t vallabh4/numeric:"GIT_COMMIT" .'
            sh 'docker push vallabh4/numeric:"GIT_COMMIT"'
            }
        }
      }
    }
}
}
