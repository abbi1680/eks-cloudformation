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
                        sh 'hadolint ./Dockerfile | tee -a hadolint_lint.txt'
                        sh '''
                            lintErrors=$(stat --printf="%s"  hadolint_lint.txt)
                            if [ "$lintErrors" -gt "0" ]; then
                                echo "Errors have been found, please see below"
                                cat hadolint_lint.txt
                                exit 1
                            else
                                echo "There are no erros found on Dockerfile!!"
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
               aquaMicroscanner imageName: "${registry}", notCompliesCmd: 'exit 1', onDisallowed: 'fail', outputFormat: 'html'
            }
        }
        stage('Push Container Image') {
            steps {
                script {
                    docker.withRegistry( '', registryCredential ) {
                        resnetImage.push()
                        resnetImage.push('latest')
                    }
                }
            }
        }
        stage ('Security Analysis - k8s Resource ') {
           steps {
               docker.image('kubesec/kubesec:v2').withRun('scan /dev/stdin < k8s-resnet_server.yml') {
                   sh 'jq --exit-status '.score > 10' >/dev/null'
               }
            }
        }
        stage('Deploy') {
            withKubeConfig([credentialsId: 'kube-config', 
                            serverUrl: 'https://api.k8s.my-company.com',
                            namespace: 'staging'
                            ]) {
                                    sh 'kubectl apply -f my-kubernetes-directory'
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
           deleteDir()
           sh "docker rmi ${registry}:${env.BUILD_ID}"
       }
    //TODO: Submit Slack to say successful deployment
    }
}