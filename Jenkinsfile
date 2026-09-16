pipeline {
    agent any

    stages {

        stage('Build & Test') {
            steps {
                dir('backend') {
                    sh './mvnw clean test'
                }
            }
        }

        stage('JaCoCo Coverage') {
            steps {
                jacoco(
                    execPattern: 'backend/target/jacoco.exec',
                    classPattern: 'backend/target/classes',
                    sourcePattern: 'backend/src/main/java'
                )
            }
        }

        stage('SonarQube Analysis') {
            steps {
                dir('backend') {
                    withSonarQubeEnv('SonarQube') {
                        sh './mvnw sonar:sonar -Dsonar.projectKey=Smartbank-backend'
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

    }

    post {
        success {
            echo 'SmartBank CI pipeline completed successfully with JaCoCo and SonarQube analysis!'
        }

        failure {
            echo 'SmartBank CI pipeline failed.'
        }
    }
}

