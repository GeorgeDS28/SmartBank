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

    }

    post {
        success {
            echo 'SmartBank CI pipeline completed successfully!'
        }

        failure {
            echo 'SmartBank CI pipeline failed.'
        }
    }
}