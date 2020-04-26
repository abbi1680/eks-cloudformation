properties([pipelineTriggers([githubPush()])])

pipeline {
    agent any
    environment {
        registry = "mansong/resnet_tfserving"
        registryCredential = "dockerhub"
    }
    stages {
        stage('Lint Dockerfile') {
            steps {
                script{
                    docker.image('hadolint/hadolint:latest').inside() {
                        sh '''
                            hadolint ./Dockerfile | tee -a hadolint_lint.txt;
                            if [ -s hadolint_lint.txt ]
                                then
                                    echo "Errors have been found, please see below"
                                    cat hadolint_lint.txt
                                    exit 1
                                else
                                    echo "There are no errors found"
                            fi
                            '''
                        }
                    }
                }
            }
        stage('Build Container Image') {
            steps {
                script {
                    def resnetImage = docker.build registry + ":${env.BUILD_ID}"
                }
            }
        }
        stage ('Scan Container Image') {
           steps {
               aquaMicroscanner imageName: "${env.registry}:${env.BUILD_ID}", notCompliesCmd: 'exit 1', onDisallowed: 'fail', outputFormat: 'html'
            }
        }
        stage ('Security Analysis - k8s Resources') {
           steps {
               script {
                   sh "docker run -i kubesec/kubesec:v2 scan /dev/stdin < staging/resnet-deployment.yml | jq --exit-status '.[0].score? > 3' >/dev/null"
               }
            }
        }
        stage('Push Container Image') {
            steps {
                script {
                    def resnetImage = docker.build registry + ":${env.BUILD_ID}"
                    docker.withRegistry( '', "${env.registryCredential}" ) {
                        resnetImage.push()
                        resnetImage.push('latest')
                    }
                }
            }
        }
        stage('GitOps k8s Deploy') {
            steps {
                script {
                    def deploymentConfig = "./resnet-server/resnet-deployment.yml"
                    sh """
                        ./tools/updateImage.sh ${env.registry}:${env.BUILD_ID} ${deploymentConfig}
                        git add ${deploymentConfig}
                        git commit -m "Update resnet-server image to ${env.registry}:${env.BUILD_ID}"
                        git push
                       """
                    }
                }
            }
        }
    }
    /* Cleanup workspace */
    post {
        always {
           echo "Cleaning up directory"
           deleteDir()
           echo "Cleaning up container image"
           sh "docker rmi ${registry}:${env.BUILD_ID}"
       }
    }
}