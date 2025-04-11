pipeline {
  agent any
  tools { 
        maven 'Maven_3_2_5'  
    }
   stages{
    stage('CompileandRunSonarAnalysis') {
            steps {	
		sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=vincebuggywebapp -Dsonar.organization=vincebuggywebapp -Dsonar.host.url=https://sonarcloud.io -Dsonar.token=182d66a24de604373489a80b705561d76f4650dc'
			}
    }

	stage('RunSCAAnalysisUsingSnyk') {
            steps {		
				withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
          sh 'echo SNYK_TOKEN variable starts with: ${SNYK_TOKEN:0:4}'
          sh 'mvn snyk:test -fn'
				}
			}
    }

	stage('Build') { 
            steps { 
               withDockerRegistry([credentialsId: "dockerlogin", url: "https://hub.docker.com/repository/docker/vincewee/vince"]) {
                 script{
                 app =  docker.build("latest")
                 }
               }
            }
    }

	stage('Push') {
            steps {
                script{
                    docker.withRegistry('https://022498999951.dkr.ecr.us-west-2.amazonaws.com', 'ecr:us-west-2:aws-credentials') {
                    app.push("latest")
                    }
                }
            }
    	}
	    
  }
}
