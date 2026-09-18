/*
 * SIT223/SIT753 7.3HD — Jenkins DevOps Pipeline
 * Project: ThothTech Documentation Website (Astro + Starlight, Node/TypeScript)
 *
 * 7 stages: Build, Test, Code Quality, Security, Deploy, Release, Monitoring.
 * Designed for full automation with no manual approval gates (Top HD requires
 * "full automation and smooth transitions between stages").
 *
 * Prerequisites on the Jenkins host (see SETUP.md):
 *   - Node.js + npm on PATH (NodeJS plugin recommended)
 *   - Docker Desktop running, docker + "docker compose" on PATH
 *   - Trivy CLI on PATH (scripts/install-trivy.sh will install it if missing)
 *   - SonarQube reachable at http://localhost:9000 (docker-compose.sonarqube.yml)
 *   - A Jenkins "SonarQube servers" entry named LocalSonarQube (Manage Jenkins > System)
 *   - Credential "sonarqube-token" (Secret text) with a SonarQube user token
 */

pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    environment {
        IMAGE_NAME         = "thothtech-docs"
        REGISTRY           = "localhost:5000"
        SONAR_PROJECT_KEY  = "thothtech-documentation-website"
        BUILD_VERSION      = "1.0.${BUILD_NUMBER}"
        GIT_SHORT_SHA      = "" // set during Build stage
        PATH               = "/Users/Naren/.nvm/versions/node/v22.20.0/bin:/usr/local/bin:/opt/homebrew/bin:${env.PATH}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_SHORT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                }
                echo "Building commit ${env.GIT_SHORT_SHA} as version ${env.BUILD_VERSION}"
            }
        }

        stage('Build') {
            steps {
                sh 'npm ci'
                sh 'npm run build'
                sh """
                    docker build -f Dockerfile.prod \
                        -t ${IMAGE_NAME}:${BUILD_VERSION} \
                        -t ${IMAGE_NAME}:${GIT_SHORT_SHA} \
                        -t ${IMAGE_NAME}:latest .
                """
                // Push to the local Jenkins-managed registry for tagged artifact storage
                sh """
                    docker tag ${IMAGE_NAME}:${BUILD_VERSION} ${REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION}
                    docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_VERSION} || echo 'Registry not running yet — see SETUP.md step 3'
                """
            }
            post {
                success {
                    archiveArtifacts artifacts: 'dist/**', fingerprint: true, allowEmptyArchive: false
                }
            }
        }

        stage('Test') {
            steps {
                sh 'mkdir -p reports'
                sh 'npm run test:ci'
            }
            post {
                always {
                    junit testResults: 'reports/junit.xml', allowEmptyResults: true
                    archiveArtifacts artifacts: 'coverage/**', allowEmptyArchive: true
                }
            }
        }

        stage('Code Quality') {
            environment {
                // "SonarScanner" = the name given to the tool in
                // Manage Jenkins > Tools, installed by the SonarQube
                // Scanner plugin (see SETUP.md step 6).
                SCANNER_HOME = tool 'SonarScanner'
            }
            steps {
                withSonarQubeEnv('LocalSonarQube') {
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                            -Dsonar.projectVersion=${BUILD_VERSION}
                    """
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

        stage('Security') {
            steps {
                sh 'chmod +x scripts/*.sh'
                sh './scripts/install-trivy.sh'
                sh 'IMAGE_NAME=${IMAGE_NAME} IMAGE_TAG=${BUILD_VERSION} ./scripts/security-scan.sh'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/npm-audit.json,reports/trivy-*.json', allowEmptyArchive: true
                }
            }
        }

        stage('Deploy') {
            steps {
                sh "IMAGE_NAME=${IMAGE_NAME} ./scripts/deploy.sh staging ${BUILD_VERSION}"
            }
        }

        stage('Release') {
            steps {
                sh "IMAGE_NAME=${IMAGE_NAME} ./scripts/release.sh ${BUILD_VERSION}"
                sh """
                    git tag -a v${BUILD_VERSION} -m "Automated release ${BUILD_VERSION} (${GIT_SHORT_SHA})" || true
                    git push origin v${BUILD_VERSION} || echo 'Configure git push credentials in Jenkins to enable tag push'
                """
            }
        }

        stage('Monitoring') {
            steps {
                sh 'chmod +x scripts/*.sh'
                sh './scripts/monitoring-check.sh'
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed at a stage — attempting automatic rollback of production if Release had already run"
            sh './scripts/rollback.sh || true'
        }
        always {
            sh 'docker image prune -f || true'
        }
    }
}
