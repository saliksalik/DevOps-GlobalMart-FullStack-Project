// ──────────────────────────────────────────────────────────────────────────────
// Project Phoenix — GlobalMart CI/CD Pipeline
// Phases: Checkout → Build → Test → Scan → Archive → Docker Build → Deploy
// ──────────────────────────────────────────────────────────────────────────────

pipeline {

    // Run on the Docker agent we configured in docker-compose
    agent {
        label 'docker-agent-01'
    }

    // ── Pipeline-level env vars ──────────────────────────────────────────────
    environment {
        APP_NAME        = 'globalmart-api'
        DOCKER_IMAGE    = "globalmart/${APP_NAME}"
        DOCKER_REGISTRY = 'docker.io'
        // Credentials stored in Jenkins Credentials Manager
        DOCKER_CREDS    = credentials('dockerhub-credentials')
        SONAR_TOKEN     = credentials('sonar-token')
        BUILD_VERSION   = "${APP_NAME}-${BUILD_NUMBER}"
    }

    // ── Trigger: poll SCM every 5 mins OR on GitHub webhook ─────────────────
    triggers {
        pollSCM('H/5 * * * *')
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        // ── Stage 1: Code Checkout ─────────────────────────────────────────
        stage('Checkout') {
            steps {
                echo "=== STAGE 1: Checkout from SCM ==="
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.GIT_BRANCH_NAME  = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim()
                    echo "Branch: ${env.GIT_BRANCH_NAME} | Commit: ${env.GIT_COMMIT_SHORT}"
                }
            }
        }

        // ── Stage 2: Install Dependencies / Build ─────────────────────────
        stage('Build') {
            steps {
                echo "=== STAGE 2: Build — Install Dependencies ==="
                dir('app') {
                    sh '''
                        echo "Node version: $(node --version)"
                        echo "NPM  version: $(npm --version)"
                        npm ci --prefer-offline
                        echo "Dependencies installed successfully."
                    '''
                }
            }
        }

        // ── Stage 3: Unit Tests + Coverage Report ─────────────────────────
        stage('Unit Test') {
            steps {
                echo "=== STAGE 3: Unit Tests ==="
                dir('app') {
                    sh 'npm test -- --ci --reporters=default --reporters=jest-junit'
                }
            }
            post {
                always {
                    // Publish JUnit test results in Jenkins UI
                    junit allowEmptyResults: true, testResults: 'app/junit.xml'
                    // Publish HTML coverage report
                    publishHTML(target: [
                        allowMissing         : false,
                        alwaysLinkToLastBuild: true,
                        keepAll              : true,
                        reportDir            : 'app/coverage/lcov-report',
                        reportFiles          : 'index.html',
                        reportName           : 'Code Coverage Report'
                    ])
                }
            }
        }

        // ── Stage 4: Docker Build ──────────────────────────────────────────
        stage('Docker Build') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                echo "=== STAGE 4: Build Docker Image ==="
                dir('app') {
                    sh """
                        docker build \
                          --build-arg BUILD_NUMBER=${BUILD_NUMBER} \
                          --build-arg GIT_COMMIT=${env.GIT_COMMIT_SHORT} \
                          -t ${DOCKER_IMAGE}:${env.GIT_COMMIT_SHORT} \
                          -t ${DOCKER_IMAGE}:latest \
                          .
                        docker images | grep ${APP_NAME}
                    """
                }
            }
        }

        // ── Stage 5: Push to Registry ─────────────────────────────────────
        stage('Push Image') {
            when { branch 'main' }
            steps {
                echo "=== STAGE 5: Push to Docker Hub ==="
                sh """
                    echo ${DOCKER_CREDS_PSW} | docker login -u ${DOCKER_CREDS_USR} --password-stdin
                    docker push ${DOCKER_IMAGE}:${env.GIT_COMMIT_SHORT}
                    docker push ${DOCKER_IMAGE}:latest
                    docker logout
                """
            }
        }

        // ── Stage 6: Archive Artifacts ────────────────────────────────────
        stage('Archive Artifacts') {
            steps {
                echo "=== STAGE 6: Archive Artifacts ==="
                // Archive package.json and test results as build artifacts
                archiveArtifacts artifacts: 'app/package.json, app/coverage/**/*', allowEmptyArchive: true
                // Record build info
                sh """
                    echo "Build: ${BUILD_NUMBER}" > build-info.txt
                    echo "Commit: ${env.GIT_COMMIT_SHORT}" >> build-info.txt
                    echo "Branch: ${env.GIT_BRANCH_NAME}" >> build-info.txt
                    echo "Image:  ${DOCKER_IMAGE}:${env.GIT_COMMIT_SHORT}" >> build-info.txt
                    echo "Date:   \$(date)" >> build-info.txt
                    cat build-info.txt
                """
                archiveArtifacts artifacts: 'build-info.txt'
            }
        }

        // ── Stage 7: Deploy to Dev (Kubernetes) ───────────────────────────
        stage('Deploy to Dev') {
            when { branch 'develop' }
            steps {
                echo "=== STAGE 7: Deploy to Dev K8s Namespace ==="
                sh """
                    kubectl set image deployment/globalmart-deployment \
                      globalmart=${DOCKER_IMAGE}:${env.GIT_COMMIT_SHORT} \
                      --namespace=dev \
                      --record
                    kubectl rollout status deployment/globalmart-deployment --namespace=dev
                """
            }
        }

        // ── Stage 8: Deploy to Production (Blue-Green) ────────────────────
        stage('Deploy to Production') {
            when { branch 'main' }
            input {
                message "Deploy to PRODUCTION?"
                ok "Yes, deploy now!"
                submitter "admin,release-manager"
            }
            steps {
                echo "=== STAGE 8: Blue-Green Deploy to Production ==="
                sh 'bash scripts/blue-green-deploy.sh'
            }
        }
    }

    // ── Post Actions ─────────────────────────────────────────────────────────
    post {
        success {
            echo "✅ Pipeline SUCCEEDED — Build #${BUILD_NUMBER} | Commit: ${env.GIT_COMMIT_SHORT}"
            // emailext(
            //     subject: "✅ GlobalMart Build #${BUILD_NUMBER} Passed",
            //     body: "Branch: ${env.GIT_BRANCH_NAME}\nCommit: ${env.GIT_COMMIT_SHORT}",
            //     to: 'devops-team@globalmart.com'
            // )
        }
        failure {
            echo "❌ Pipeline FAILED — Build #${BUILD_NUMBER}"
            // Notify on failure
        }
        always {
            // Clean workspace after build
            cleanWs()
        }
    }
}
