pipeline {
    agent any

    #-----------------------------------
    # Environment Variables
    #-----------------------------------
    environment {
        DOCKER_IMAGE   = 'vincewee/easybuggy'
        DOCKER_TAG     = '1.0.0'
        ECR_REGISTRY   = '022498999951.dkr.ecr.eu-west-2.amazonaws.com'
    }

    #-----------------------------------
    # Required Tools
    #-----------------------------------
    tools {
        maven 'Maven_3_2_5'
    }

    #-----------------------------------
    # Pipeline Stages
    #-----------------------------------
    stages {
        #-----------------------------------
        # Stage 1: Code Analysis
        #-----------------------------------
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

        #-----------------------------------
        # Stage 2: Docker Build
        #-----------------------------------
        stage('Build') {
            steps {
                withDockerRegistry([
                    credentialsId: "dockerlogin",
                    url: "https://index.docker.io/v1/"
                ]) {
                    script {
                        app = docker.build(
                            "${DOCKER_IMAGE}:${DOCKER_TAG}"
                        )
                    }
                }
            }
        }

        #-----------------------------------
        # Stage 3: ECR Push
        #-----------------------------------
        stage('Push') {
            steps {
                script {
                    docker.withRegistry(
                        "https://${ECR_REGISTRY}",
                        'ecr:eu-west-2:aws-credentials'
                    ) {
                        app.push("${DOCKER_TAG}")
                    }
                }
            }
        }
    }

    #-----------------------------------
    # Post-Build Actions
    #-----------------------------------
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