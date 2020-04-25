properties([pipelineTriggers([githubPush()])])

pipeline {
    agent any
    environment {
        registry = "mansong/resnet_tfserving"
        registryCredential = "dockerhub"
    }
    stages {
        // stage ('Start') {
        //     slackSend (color: '#FFFF00', message: "STARTED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        // }
        // stage('Lint Dockerfile') {
        //     steps {
        //         script{
        //             docker.image('hadolint/hadolint:latest').inside() {
        //                 sh '''
        //                     hadolint ./Dockerfile | tee -a hadolint_lint.txt;
        //                     if [ -s hadolint_lint.txt ]
        //                         then
        //                             echo "Errors have been found, please see below"
        //                             cat hadolint_lint.txt
        //                             exit 1
        //                         else
        //                             echo "There are no errors found"
        //                     '''
        //                 }
        //             }
        //         }
        //     }
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
        stage ('Security Analysis - k8s Resource ') {
           steps {
               script {
                   sh "docker run -i kubesec/kubesec:v2 scan /dev/stdin < k8s-resnet_server.yml"
               }
            }
        }
        stage('Deploy') {
            steps {
                withKubeConfig([credentialsId: 'kube-config',
                serverUrl: 'https://api.k8s.my-company.com',
                namespace: 'staging'
                ]) {
                        sh 'kubectl apply -f k8s-resnet_server.yml'
                    }
            }
        }
        stage('Post Deploy Test') {
            steps {
                    sh './tools/run_in_docker.sh python tensorflow_serving/example/resnet_client_grpc.py'
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
        // success {
        //    slackSend (channel: '#ops-room',
        //              color: 'good',
        //              message: "The pipeline ${currentBuild.fullDisplayName} completed successfully.")
        // }
        // failure {
        //     slackSend (color: '#FF0000', message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        // }
    }
}