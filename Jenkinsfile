pipeline {
  agent any
  tools { 
        maven 'Maven_3_2_5'  
    }
   stages{
    stage('CompileandRunSonarAnalysis') {
            steps {	
                withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]) {
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

	stage('Build') { 
            steps { 
               withDockerRegistry([credentialsId: "dockerlogin", url: "https://hub.docker.com/repository/docker/vincewee/easybuggy"]) {
                 script{
                 app =  docker.build("1.0.0")
                 }
               }
            }
    }

// 	stage('Push') {
//             steps {
//                 script{
//                     docker.withRegistry('https://022498999951.dkr.ecr.us-west-2.amazonaws.com', 'ecr:us-west-2:aws-credentials') {
//                     app.push("latest")
//                     }
//                 }
//             }
//     	}
	    
//   }
// }
