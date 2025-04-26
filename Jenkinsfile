pipeline {
    agent any

    //-----------------------------------
    // Environment Variables
    //-----------------------------------
    environment {
    DOCKER_IMAGE   = 'vincewee/easybuggy'     
    DOCKER_TAG     = '2.0.0'
    ECR_REGISTRY   = '022498999951.dkr.ecr.eu-west-2.amazonaws.com'
    ECR_REPOSITORY = 'buyggy-repository'      
    ECR_IMAGE      = "${ECR_REGISTRY}/${ECR_REPOSITORY}"  
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
                    // Tag the local image with the ECR repository path before pushing
                    sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${ECR_IMAGE}:${DOCKER_TAG}"
                    
                    docker.withRegistry(
                        "https://${ECR_REGISTRY}",
                        'ecr:eu-west-2:aws-credentials'
                    ) {
                        docker.image("${ECR_IMAGE}:${DOCKER_TAG}").push()
                        
                        def gitCommit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                        sh "docker tag ${DOCKER_IMAGE}:${gitCommit} ${ECR_IMAGE}:${gitCommit}"
                        docker.image("${ECR_IMAGE}:${gitCommit}").push()
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
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        always {
            cleanWs()
        }
    }
}