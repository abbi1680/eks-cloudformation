properties([pipelineTriggers([githubPush()])])

pipeline {
    agent any
    environment {
        registry = "mansong/resnet_tfserving"
        registryCredential = "dockerhub"
        GIT_SSH_COMMAND = "ssh -o StrictHostKeyChecking=no"
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
                    def imageTag = "${env.registry}" + ":${env.BUILD_ID}"
                    def gitUrl = "git@github.com:mansong1/eks-cloudformation.git"
                    def config = readYaml file: deploymentConfig
                    config.spec.template.spec.containers[0].image = imageTag
                    sh "rm ${deploymentConfig}"
                    writeYaml file: deploymentConfig, data: config
                    sshagent(credentials: ['githubssh']) {
                        sh """
                            git config --global user.email "jenkins@minikube"
                            git config --global user.name "Jenkins"
                            git remote set-url origin ${gitUrl}
                            git add ${deploymentConfig}
                            git commit -m "Update resnet-server image to ${imageTag}"
                            git push origin master --force
                       """
                    }
                }
            }
        }
    }
    post {
        success {
            slackSend ( channel: 'microservices', 
                        color: 'good', 
                        message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL}), Image ${env.registry}:${env.BUILD_ID} deployed", 
                        notifyCommitters: true, 
                        tokenCredentialId: 'slack' )
        }
        failure {
            slackSend (color: 'danger', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})", notifyCommitters: true, tokenCredentialId: 'slack' )
        }
        always {
           echo "Cleaning up directory"
           deleteDir()
           echo "Cleaning up container image"
           sh "docker rmi ${registry}:${env.BUILD_ID}"
       }
    }
}