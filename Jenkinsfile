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
          - name: container-tools
            image: vallabh4/container-tools:latest
            command:
            - /bin/sh
            args:
            - -c
            - |
              apt-get update && apt-get install -y jq
              sleep 99d
            tty: true
          - name: docker
            image: docker:dind
            securityContext:
              privileged: true
            command:
            - sh
            - -c
            args:
            - apk add --no-cache curl jq && dockerd --host=tcp://127.0.0.1:2375 --host=unix:///var/run/docker.sock
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
  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "vallabh4/numeric:${GIT_COMMIT}"
    KUBECONFIG = credentials('kube-config')
    applicationURI="increment/99"
    applicationURL="http://3.110.107.159"
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
            sh "sh kubesec-scan.sh"
          }
          },
          "Trivy Scan": {
            container('docker') {
            sh "sh trivy-k8s-scan.sh"
          }
          }
        )
      }
    }
stage('K8S Deployment - DEV') {
  steps {
    parallel(
      "Deployment": {
        container('container-tools') {
          withAWS(credentials: 'aws',region: 'ap-south-1') {
            // sh 'aws s3 ls' // List S3 buckets to test AWS credentials
            sh 'aws eks update-kubeconfig --region ap-south-1 --name shri'
            sh 'sed -i "s#replace#${imageName}#g" k8s_deployment_service.yaml'
            sh 'cat k8s_deployment_service.yaml'
            sh 'kubectl -n app apply -f k8s_deployment_service.yaml'
          }
        }
      },
      "Rollout Status": {
        container('container-tools') {
          withAWS(credentials: 'aws',region: 'ap-south-1') {
            sh 'aws eks update-kubeconfig --region ap-south-1 --name shri'
            sh 'bash k8s-deployment-rollout-status.sh'
        }
        }
      }
    )
  }
}
stage('Integration Tests - DEV') {
      steps {
         container('container-tools') {
          script {
            try {
              withAWS(credentials: 'aws',region: 'ap-south-1') {
                sh 'aws eks update-kubeconfig --region ap-south-1 --name shri'
                sh "bash integration-test.sh"
              }
            } catch (e) {
              withAWS(credentials: 'aws',region: 'ap-south-1') {
                sh 'aws eks update-kubeconfig --region ap-south-1 --name shri'
                sh "kubectl -n app rollout undo deploy ${deploymentName}"
              }
              throw e
            }
          }
         }
      }
    }
    stage('OWASP ZAP - DAST') {
      steps {
        container('docker') {
            sh 'sh zap.sh'
        }
      }
    }

    stage('Prompte to PROD?') {
      steps {
        timeout(time: 2, unit: 'DAYS') {
          input 'Do you want to Approve the Deployment to Production Environment/Namespace?'
        }
      }
    }

stage('K8S Deployment - PROD') {
  steps {
    parallel(
      "Deployment": {
        container('container-tools') {
          withAWS(credentials: 'aws',region: 'ap-south-1') {
            // sh 'aws s3 ls' // List S3 buckets to test AWS credentials
            sh 'aws eks update-kubeconfig --region ap-south-1 --name shri'
            sh 'sed -i "s#replace#${imageName}#g" k8s_deployment_service_prod.yaml'
            sh 'cat k8s_deployment_service_prod.yaml'
            sh 'kubectl -n prod apply -f k8s_deployment_service_prod.yaml'
          }
        }
      },
      "Rollout Status": {
        container('container-tools') {
          withAWS(credentials: 'aws',region: 'ap-south-1') {
            sh 'aws eks update-kubeconfig --region ap-south-1 --name shri'
            sh 'bash k8s-deployment-rollout-status-prod.sh'
        }
        }
      }
    )
  }
}
    stage('Integration Tests - PROD') {
      steps {
         container('container-tools') {
          script {
            try {
              withAWS(credentials: 'aws',region: 'ap-south-1') {
                sh 'aws eks update-kubeconfig --region ap-south-1 --name shri'
                sh "bash integration-test-prod.sh"
              }
            } catch (e) {
              withAWS(credentials: 'aws',region: 'ap-south-1') {
                sh 'aws eks update-kubeconfig --region ap-south-1 --name shri'
                sh "kubectl -n prod rollout undo deploy ${deploymentName}"
              }
              throw e
            }
          }
         }
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
