pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
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

        stage('Detect Runtime') {
            steps {
                script {
                    def hasNode = (sh(returnStatus: true, script: 'command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1') == 0)
                    env.HAS_NODE = hasNode ? 'true' : 'false'
                    if (hasNode) {
                        echo 'Node and npm found on Jenkins executor.'
                    } else {
                        echo 'Node/npm not available on Jenkins executor. Install/Test stages will be skipped for this local run.'
                    }
                }
            }
        }

        stage('Install Dependencies') {
            when {
                expression { env.HAS_NODE == 'true' }
            }
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
            when {
                expression { env.HAS_NODE == 'true' }
            }
            steps {
                echo '=== STAGE 3: Run tests ==='
                dir('app') {
                    sh 'npm test'
                }
            }
        }

        stage('Runtime Note') {
            when {
                expression { env.HAS_NODE != 'true' }
            }
            steps {
                echo 'Node/npm missing on executor. Pipeline continued to demonstrate SCM checkout and artifact flow.'
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
            deleteDir()
        }
    }
}
