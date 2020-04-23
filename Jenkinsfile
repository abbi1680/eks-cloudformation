properties([pipelineTriggers([githubPush()])])

pipeline {
    agent any
    stages {
        stage ('Checkout') {
            checkout scm
        }
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
                sh 'hadolint Dockerfile'
            }
        }
        stage('Build Container Image') {
            sh 'docker image build -t mansong/resnet_tfserving .'
        }
        stage ('Scan Container Image') {
            aquaMicroscanner imageName: 'mansong/resnet_tfserving', notCompliesCmd: 'exit 1', onDisallowed: 'fail', outputFormat: 'html'
        }
        stage('Push Container Image') {
            withCredentials([
                usernamePassword(credentialsId: 'docker-credentials',
                        usernameVariable: 'USERNAME',
                        passwordVariable: 'PASSWORD')]) {
                            sh 'docker login -p "${PASSWORD}" -u "${USERNAME}"'
                            sh 'docker image push ${USERNAME}/mansong/resnet_tfserving:latest'
                        }
        }
        stage ('Security Analysis - k8s Resource ') {
            sh 'docker run -i kubesec/kubesec:v2 scan /dev/stdin < k8s-resnet_server.yml | jq --exit-status '.score > 10' >/dev/null'
        }
        stage('Deploy') {
            withCredentials([
                file(credentialsId: 'kube-config',
                        variable: 'KUBECONFIG')]) {
                            sh 'kubectl apply -f deployment.yaml -n staging'
                    }
                }
            }
        stage('Post Deploy Test') {
            steps {
                echo "Testing"
                //tools/run_in_docker.sh python tensorflow_serving/example/resnet_client_grpc.py
                }
            }
    }
    /* Cleanup workspace */
    post {
       always {
           deleteDir()
       }
    //TODO: Submit Slack to say successful deployment
    }
}