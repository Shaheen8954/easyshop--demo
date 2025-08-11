@Library('EasyShop-jenkins-shared-lib@main') _

pipeline {
    agent any
    
    environment {
        // Update the main app image name to match the deployment file
        DOCKER_IMAGE_NAME = 'shaheen8954/easyshop-demo'
        DOCKER_MIGRATION_IMAGE_NAME = 'shaheen8954/easyshop-backend'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        AWS_CREDENTIALS = credentials('aws-credentials')
        GITHUB_CREDENTIALS = credentials('github-credentials')
        GIT_BRANCH = "main"
    }
    
    stages {
        stage('Check for CI Skip') {
            steps {
                script {
                    def commitMessage = sh(script: 'git log -1 --pretty=%B', returnStdout: true).trim()
                    echo "Commit message: ${commitMessage}"
                    if (commitMessage.contains('[ci skip]') || commitMessage.contains('[skip ci]')) {
                        echo "Found CI skip directive in commit message, aborting build"
                        currentBuild.result = 'ABORTED'
                        error("Build skipped due to [ci skip] directive")
                    }
                }
            }
        }
        
        stage('Cleanup Workspace') {
            steps {
                script {
                    cleanupWorkspace()
                }
            }
        }
        
        stage('Clone Repository') {
            steps {
                script {
                    checkoutRepo()
                }
            }
        }
        
        stage('Build Docker Images') {
            parallel {
                stage('Build Main App Image') {
                    steps {
                        script {
                            buildDockerImage(
                                imageName: env.DOCKER_IMAGE_NAME,
                                imageTag: env.DOCKER_IMAGE_TAG,
                                dockerfile: 'Dockerfile',
                                context: '.'
                            )
                        }
                    }
                }
                
                stage('Build Migration Image') {
                    steps {
                        script {
                            buildDockerImage(
                                imageName: env.DOCKER_MIGRATION_IMAGE_NAME,
                                imageTag: env.DOCKER_IMAGE_TAG,
                                dockerfile: 'scripts/Dockerfile.migration',
                                context: '.'
                            )
                        }
                    }
                }
            }
        }
        
        stage('Run Unit Tests') {
            steps {
                script {
                    runUnitTests()
                }
            }
        }
        
        stage('Security Scan with Trivy') {
            steps {
                script {
                    // Create directory for results
                    sh "mkdir -p trivy-results"
                    
                    // Run scans sequentially to avoid conflicts
                    echo "Scanning main application image..."
                    trivyScan(
                        imageName: env.DOCKER_IMAGE_NAME,
                        imageTag: env.DOCKER_IMAGE_TAG,
                        threshold: 150,
                        severity: 'HIGH,CRITICAL'
                    )
                    
                    echo "Scanning migration image..."
                    trivyScan(
                        imageName: env.DOCKER_MIGRATION_IMAGE_NAME,
                        imageTag: env.DOCKER_IMAGE_TAG,
                        threshold: 150,
                        severity: 'HIGH,CRITICAL'
                    )
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-results/*.json,trivy-results/*.html', allowEmptyArchive: true
                }
            }
        }
        
        stage('Push Docker Images') {
            parallel {
                stage('Push Main App Image') {
                    steps {
                        script {
                            pushDockerImage(
                                imageName: env.DOCKER_IMAGE_NAME,
                                imageTag: env.DOCKER_IMAGE_TAG,
                                credentials: 'docker-hub-credentials'
                            )
                        }
                    }
                }
                
                stage('Push Migration Image') {
                    steps {
                        script {
                            pushDockerImage(
                                imageName: env.DOCKER_MIGRATION_IMAGE_NAME,
                                imageTag: env.DOCKER_IMAGE_TAG,
                                credentials: 'docker-hub-credentials'
                            )
                        }
                    }
                }
            }
        }
        
        // Add this new stage
        stage('Update Kubernetes Manifests') {
            steps {
                script {
                    updateK8sManifests(
                        imageTag: env.DOCKER_IMAGE_TAG,
                        manifestsPath: 'kubernetes',
                        gitCredentials: 'github-credentials',
                        gitUserName: 'Jenkins CI',
                        gitUserEmail: 'nshaheen488@gmail.com'
                    )
                }
            }
        }
    }
    
    post {
        always {
            script {
                generateReport(
                    projectName: 'EasyShop',
                    imageName: "${env.DOCKER_IMAGE_NAME}, ${env.DOCKER_MIGRATION_IMAGE_NAME}",
                    imageTag: env.DOCKER_IMAGE_TAG
                )
            }
        }
    }
}
