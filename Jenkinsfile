pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 60, unit: 'MINUTES')
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

        stage('Detect Tools') {
            steps {
                script {
                    env.HAS_NODE = (sh(returnStatus: true, script: 'command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1') == 0) ? 'true' : 'false'
                    env.HAS_DOCKER = (sh(returnStatus: true, script: 'command -v docker >/dev/null 2>&1') == 0) ? 'true' : 'false'
                    env.HAS_KUBECTL = (sh(returnStatus: true, script: 'command -v kubectl >/dev/null 2>&1') == 0) ? 'true' : 'false'
                    env.IMAGE_NAME = env.DOCKER_IMAGE ?: 'project-phoenix-globalmart-api'
                    env.IMAGE_TAG = env.GIT_COMMIT_SHORT ?: 'latest'
                    env.FULL_IMAGE = env.DOCKER_REGISTRY ? "${env.DOCKER_REGISTRY}/${env.IMAGE_NAME}" : env.IMAGE_NAME
                    env.DOCKER_PUSH_ENABLED = (env.DOCKER_REGISTRY && env.DOCKER_REGISTRY != '') ? 'true' : 'false'

                    echo "Node/npm available: ${env.HAS_NODE}"
                    echo "Docker available: ${env.HAS_DOCKER}"
                    echo "kubectl available: ${env.HAS_KUBECTL}"
                    echo "Image: ${env.FULL_IMAGE}:${env.IMAGE_TAG}"
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

        stage('Docker Build') {
            when {
                expression { env.HAS_DOCKER == 'true' }
            }
            steps {
                echo '=== STAGE 4: Build Docker image ==='
                dir('app') {
                    sh '''
                        echo "Building Docker image ${FULL_IMAGE}:${IMAGE_TAG}"
                        docker build -t "${FULL_IMAGE}:${IMAGE_TAG}" .
                        docker tag "${FULL_IMAGE}:${IMAGE_TAG}" "${FULL_IMAGE}:latest" || true
                    '''
                }
            }
        }

        stage('Docker Login') {
            when {
                expression { env.HAS_DOCKER == 'true' && env.DOCKER_REGISTRY && env.DOCKER_REGISTRY != '' && env.DOCKER_REGISTRY_CREDENTIALS_ID }
            }
            steps {
                echo '=== STAGE 5: Docker login ==='
                withCredentials([usernamePassword(credentialsId: env.DOCKER_REGISTRY_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin ${DOCKER_REGISTRY}'
                }
            }
        }

        stage('Docker Push') {
            when {
                expression { env.HAS_DOCKER == 'true' && env.DOCKER_PUSH_ENABLED == 'true' }
            }
            steps {
                echo '=== STAGE 6: Push Docker image ==='
                dir('app') {
                    sh '''
                        docker push "${FULL_IMAGE}:${IMAGE_TAG}"
                        docker push "${FULL_IMAGE}:latest" || true
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                expression { env.HAS_KUBECTL == 'true' }
            }
            steps {
                echo '=== STAGE 7: Deploy to Kubernetes (Blue-Green) ==='
                sh '''
                    export DOCKER_IMAGE="${FULL_IMAGE}"
                    export GIT_COMMIT_SHORT="${IMAGE_TAG}"
                    bash scripts/blue-green-deploy.sh
                '''
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo '=== STAGE 8: Archive artifacts ==='
                archiveArtifacts artifacts: 'app/package.json, app/coverage/**/*', allowEmptyArchive: true
                sh '''
                    echo "Build: $BUILD_NUMBER" > build-info.txt
                    echo "Commit: $GIT_COMMIT_SHORT" >> build-info.txt
                    echo "Branch: $GIT_BRANCH_NAME" >> build-info.txt
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
