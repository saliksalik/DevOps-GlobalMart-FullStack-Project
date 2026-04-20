pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                echo '=== STAGE 1: Checkout from SCM ==='
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.GIT_BRANCH_NAME = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                    echo "Branch: ${env.GIT_BRANCH_NAME} | Commit: ${env.GIT_COMMIT_SHORT}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                echo '=== STAGE 2: Install dependencies ==='
                dir('app') {
                    sh '''
                        echo "Node version: $(node --version)"
                        echo "NPM  version: $(npm --version)"
                        npm ci --prefer-offline
                    '''
                }
            }
        }

        stage('Unit Tests') {
            steps {
                echo '=== STAGE 3: Run tests ==='
                dir('app') {
                    sh 'npm test'
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo '=== STAGE 4: Archive artifacts ==='
                archiveArtifacts artifacts: 'app/package.json, app/coverage/**/*', allowEmptyArchive: true
                sh '''
                    echo "Build: ${BUILD_NUMBER}" > build-info.txt
                    echo "Commit: ${env.GIT_COMMIT_SHORT}" >> build-info.txt
                    echo "Branch: ${env.GIT_BRANCH_NAME}" >> build-info.txt
                    echo "Date:   $(date)" >> build-info.txt
                    cat build-info.txt
                '''
                archiveArtifacts artifacts: 'build-info.txt', allowEmptyArchive: true
            }
        }
    }

    post {
        success {
            echo "SUCCESS - Build #${BUILD_NUMBER} | Commit: ${env.GIT_COMMIT_SHORT}"
        }
        failure {
            echo "FAILURE - Build #${BUILD_NUMBER}"
        }
        always {
            cleanWs()
        }
    }
}
