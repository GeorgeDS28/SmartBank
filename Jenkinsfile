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

        stage('Docker Deploy') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'smartbank-db-password',
                        variable: 'DB_PASSWORD'
                    ),
                    string(
                        credentialsId: 'smartbank-jwt-secret',
                        variable: 'JWT_SECRET'
                    )
                ]) {
                    sh '''
                        set +x
                        trap 'rm -f .jenkins.env' EXIT

                        cat > .jenkins.env <<EOF
DB_PASSWORD=$DB_PASSWORD
JWT_SECRET=$JWT_SECRET
JWT_EXPIRATION=86400000
EOF

                        docker compose \
                          --env-file .jenkins.env \
                          -f docker/docker-compose.yml \
                          up -d --build

                        echo "SmartBank Docker deployment completed."
                    '''
                }
            }
        }

        stage('Deployment Verification') {
            steps {
                sh '''
                    echo "Checking SmartBank containers..."

                    docker compose \
                      -f docker/docker-compose.yml \
                      ps

                    echo "Waiting for backend to start..."
                    sleep 15

                    curl -f http://localhost:8081/v3/api-docs > /dev/null

                    echo "SmartBank deployment verified successfully."
                '''
            }
        }

    }

    post {
        success {
            echo 'SmartBank CI/CD pipeline completed successfully with JaCoCo, SonarQube, Quality Gate, and Docker deployment!'
        }

        failure {
            echo 'SmartBank CI/CD pipeline failed.'
        }
    }
}