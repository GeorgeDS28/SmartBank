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

    }

    post {
        success {
            echo 'SmartBank CI pipeline completed successfully with coverage!'
        }

        failure {
            echo 'SmartBank CI pipeline failed.'
        }
    }
}