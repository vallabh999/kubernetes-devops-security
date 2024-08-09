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
            - sh
            - -c
            args:
            - apk add --no-cache jq && dockerd --host=tcp://127.0.0.1:2375 --host=unix:///var/run/docker.sock
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
      stage('Unit Test - JUnit and JaCoCo') {
            steps {
                container ('maven'){
                sh "mvn test"
                }  
            }
      }
      stage('Vulnerability Scan - Docker') {
        steps {
          parallel (
            "Trivy Scan": {
              container('docker') {
                sh "sh trivy-docker-image-scan.sh"
              }
            },
            "OPA Scan": {
              container('docker') {
                sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
              }
            }
          )
        }
      }
    stage('Docker Build and Push'){
      steps{
        container ('docker'){
          withDockerRegistry([credentialsId: "docker-hub", url: ""]){
            sh 'printenv'
            sh 'docker build -t vallabh4/numeric:${GIT_COMMIT} .'
            sh 'docker push vallabh4/numeric:${GIT_COMMIT}'
            }
        }
      }
    }
    stage('Vulnerability Scan - Kubernetes') {
      steps {
        parallel(
          "OPA Scan": {
            container('docker') {
            sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
          }
          },
          "Kubesec Scan": {
            container('docker') {
            sh "bash kubesec-scan.sh"
          }
          },
          "Trivy Scan": {
            container('docker') {
            sh "bash trivy-k8s-scan.sh"
          }
          }
        )
      }
    }
    
  }
     post {
       always {
         junit 'target/surefire-reports/*.xml'
         jacoco execPattern: 'target/jacoco.exe'
         // dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
     }
   }
}
