pipeline {
    agent any
    //-----------------------------------
    // Environment Variables
    //-----------------------------------
    environment {
        DOCKER_IMAGE    = 'vincewee/easybuggy'     
        DOCKER_TAG      = '2.0.0'
        ECR_REGISTRY    = '022498999951.dkr.ecr.eu-west-2.amazonaws.com'
        ECR_REPOSITORY  = 'buyggy-repository'      
        ECR_IMAGE       = "${ECR_REGISTRY}/${ECR_REPOSITORY}"
        K8S_PATH        = 'D:\\DASTScan\\DASTScanK8s\\K8s'
        NAMESPACE       = 'devsecops'
        BUILD_VERSION   = "${BUILD_NUMBER}"
        DEPLOY_TIMEOUT  = '300s'
    }
    //-----------------------------------
    // Required Tools
    //-----------------------------------
    tools {
        maven 'Maven_3_2_5'
    }
    //-----------------------------------
    // Pipeline Stages
    //-----------------------------------
    stages {
        //-----------------------------------
        // Stage 1: Code Analysis
        //-----------------------------------
        stage('CompileandRunSonarAnalysis') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'SONAR_TOKEN',
                        variable: 'SONAR_TOKEN'
                    )
                ]) {
                    sh '''
                        mvn clean verify sonar:sonar \
                            -Dsonar.projectKey=vincebuggywebapp \
                            -Dsonar.organization=vincebuggywebapp \
                            -Dsonar.host.url=https://sonarcloud.io \
                            -Dsonar.token=${SONAR_TOKEN}
                    '''
                }
            }
        }
        //-----------------------------------
        // Stage 2: Docker Build
        //-----------------------------------
        stage('Build') {
            steps {
                withDockerRegistry([
                    credentialsId: "dockerlogin",
                    url: "https://index.docker.io/v1/"
                ]) {
                    script {
                        def buildArgs = '--no-cache=false --pull --build-arg BUILD_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" --build-arg VCS_REF="$(git rev-parse --short HEAD)"'
                        
                        def gitCommit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                        app = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}", "-f Dockerfile ${buildArgs} .")
                        
                        app.tag("${BUILD_VERSION}")
                        app.tag("${gitCommit}")
                        
                        sh "docker scan ${DOCKER_IMAGE}:${DOCKER_TAG} || true"
                        
                        sh "docker run --rm ${DOCKER_IMAGE}:${DOCKER_TAG} echo 'Container test passed'"
                    }
                }
            }
            post {
                always {
                    sh 'docker image prune -f'
                }
            }
        }
        //-----------------------------------
        // Stage 3: ECR Push
        //-----------------------------------
        stage('Push') {
            steps {
                script {
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${ECR_IMAGE}:${DOCKER_TAG}"
                    sh "docker tag ${DOCKER_IMAGE}:${BUILD_VERSION} ${ECR_IMAGE}:${BUILD_VERSION}"
                    
                    docker.withRegistry(
                        "https://${ECR_REGISTRY}",
                        'ecr:eu-west-2:aws-credentials'
                    ) {
                        docker.image("${ECR_IMAGE}:${DOCKER_TAG}").push()
                        docker.image("${ECR_IMAGE}:${BUILD_VERSION}").push()
                        
                        def gitCommit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                        sh "docker tag ${DOCKER_IMAGE}:${gitCommit} ${ECR_IMAGE}:${gitCommit}"
                        docker.image("${ECR_IMAGE}:${gitCommit}").push()
                    }
                }
            }
        }
        //-----------------------------------
        // Stage 4: Kubernetes Namespace Check
        //-----------------------------------
        stage('Ensure Kubernetes Namespace') {
            steps {
                withKubeConfig([credentialsId: 'kubelogin']) {
                    script {
                        sh """
                            if ! kubectl get namespace ${NAMESPACE} > /dev/null 2>&1; then
                                echo "Creating namespace ${NAMESPACE}"
                                kubectl create namespace ${NAMESPACE}
                            else
                                echo "Namespace ${NAMESPACE} already exists"
                            fi
                        """
                    }
                }
            }
        }
        //-----------------------------------
        // Stage 5: Kubernetes Deployment
        //-----------------------------------
        stage('Kubernetes Deployment') {
            steps {
                withKubeConfig([credentialsId: 'kubelogin']) {
                    dir("${K8S_PATH}") {
                        script {
                            sh """
                                # Update the image tag in deployment YAML
                                sed -i 's|image: ${DOCKER_IMAGE}:.*|image: ${ECR_IMAGE}:${BUILD_VERSION}|' vincewebbapp-deployment.yaml
                                
                                # Apply the deployment and service
                                kubectl apply -f vincewebbapp-deployment.yaml --namespace=${NAMESPACE}
                                kubectl apply -f vincewebbapp-service.yaml --namespace=${NAMESPACE}
                                
                                # Wait for deployment to be ready
                                kubectl rollout status deployment/$(kubectl get deployments -n ${NAMESPACE} -o jsonpath='{.items[0].metadata.name}') --namespace=${NAMESPACE} --timeout=${DEPLOY_TIMEOUT}
                            """
                        }
                    }
                }
            }
            post {
                success {
                    echo "Deployment to ${NAMESPACE} successful!"
                }
                failure {
                    echo "Deployment to ${NAMESPACE} failed!"
                    script {
                        sh """
                            kubectl get pods -n ${NAMESPACE}
                            kubectl describe deployment -n ${NAMESPACE}
                            # Get logs from the first pod in the namespace
                            FIRST_POD=\$(kubectl get pods -n ${NAMESPACE} -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
                            if [ ! -z "\$FIRST_POD" ]; then
                                kubectl logs \$FIRST_POD -n ${NAMESPACE}
                            fi
                        """
                    }
                }
            }
        }
        //-----------------------------------
        // Stage 6: Verification and Testing
        //-----------------------------------
        stage('Verify Deployment') {
            steps {
                withKubeConfig([credentialsId: 'kubelogin']) {
                    script {
                        sh """
                            echo "Retrieving service endpoint..."
                            kubectl get svc -n ${NAMESPACE}
                            
                            # Wait for pods to be ready
                            kubectl wait --for=condition=ready pods --all -n ${NAMESPACE} --timeout=${DEPLOY_TIMEOUT}
                            
                            # Get service URL
                            SERVICE_NAME=\$(kubectl get svc -n ${NAMESPACE} -o jsonpath='{.items[0].metadata.name}')
                            SERVICE_PORT=\$(kubectl get svc \$SERVICE_NAME -n ${NAMESPACE} -o jsonpath='{.spec.ports[0].port}')
                            
                            echo "Service \$SERVICE_NAME is available on port \$SERVICE_PORT"
                        """
                    }
                }
            }
        }
    }
    //-----------------------------------
    // Post-Build Actions
    //-----------------------------------
    post {
        failure {
            echo 'Pipeline failed! Check the logs for details.'
            script {
                sh """
                    echo "==== Docker Images ===="
                    docker images | grep ${DOCKER_IMAGE}
                    
                    echo "==== Kubernetes Resources ===="
                    kubectl get all -n ${NAMESPACE} || true
                """
            }
        }
        success {
            echo 'Pipeline completed successfully!'
            script {
                def deploymentInfo = """
                    Deployment Information
                    ---------------------
                    Date: ${new Date()}
                    Build: #${BUILD_NUMBER}
                    Image: ${ECR_IMAGE}:${BUILD_VERSION}
                    Namespace: ${NAMESPACE}
                    Git Commit: ${sh(script: 'git rev-parse HEAD', returnStdout: true).trim()}
                """
                writeFile file: 'deployment-info.txt', text: deploymentInfo
                archiveArtifacts artifacts: 'deployment-info.txt', fingerprint: true
            }
        }
        always {
            cleanWs()
        }
    }
}