// CI/CD pipeline:
//   code change -> GitHub webhook -> build versioned images -> push to ECR -> roll out to EKS
//
// Each run produces NEW images tagged v${BUILD_NUMBER} (previous versions are never
// overwritten). The EKS Deployments are updated with `kubectl set image`, which triggers
// the zero-downtime RollingUpdate defined in k8s/.
//
// Jenkins prerequisites (provided by jenkins/Dockerfile): docker CLI, aws CLI, kubectl.
// Credentials (Manage Jenkins > Credentials):
//   - id 'aws-credentials'  : Username/Password = AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
// Adjust AWS_REGION / CLUSTER_NAME below to match your environment.

pipeline {
    agent any

    triggers {
        githubPush()   // fired by the GitHub webhook (via ngrok)
    }

    environment {
        AWS_REGION    = 'us-east-1'
        CLUSTER_NAME  = 'task-manager'
        K8S_NAMESPACE = 'task-manager'
        BACKEND_REPO  = 'task-manager-backend'
        FRONTEND_REPO = 'task-manager-frontend'
        IMAGE_TAG     = "v${BUILD_NUMBER}"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Resolve AWS account / ECR registry') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-credentials',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        env.AWS_ACCOUNT_ID = sh(
                            script: 'aws sts get-caller-identity --query Account --output text',
                            returnStdout: true).trim()
                        env.ECR_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                        echo "ECR registry: ${env.ECR_REGISTRY}  tag: ${IMAGE_TAG}"
                    }
                }
            }
        }

        stage('ECR login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-credentials',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        aws ecr get-login-password --region "$AWS_REGION" \
                          | docker login --username AWS --password-stdin "$ECR_REGISTRY"
                    '''
                }
            }
        }

        stage('Build & push images') {
            steps {
                sh '''
                    set -e
                    # Backend
                    docker build -t "$ECR_REGISTRY/$BACKEND_REPO:$IMAGE_TAG" \
                                 -t "$ECR_REGISTRY/$BACKEND_REPO:latest" ./backend
                    docker push "$ECR_REGISTRY/$BACKEND_REPO:$IMAGE_TAG"
                    docker push "$ECR_REGISTRY/$BACKEND_REPO:latest"

                    # Frontend
                    docker build -t "$ECR_REGISTRY/$FRONTEND_REPO:$IMAGE_TAG" \
                                 -t "$ECR_REGISTRY/$FRONTEND_REPO:latest" ./frontend
                    docker push "$ECR_REGISTRY/$FRONTEND_REPO:$IMAGE_TAG"
                    docker push "$ECR_REGISTRY/$FRONTEND_REPO:latest"
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-credentials',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        set -e
                        aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

                        # Point the running Deployments at the new versioned images.
                        kubectl -n "$K8S_NAMESPACE" set image deployment/backend \
                          backend="$ECR_REGISTRY/$BACKEND_REPO:$IMAGE_TAG"
                        kubectl -n "$K8S_NAMESPACE" set image deployment/frontend \
                          frontend="$ECR_REGISTRY/$FRONTEND_REPO:$IMAGE_TAG"

                        # Gate on a successful, zero-downtime rollout.
                        kubectl -n "$K8S_NAMESPACE" rollout status deployment/backend  --timeout=180s
                        kubectl -n "$K8S_NAMESPACE" rollout status deployment/frontend --timeout=180s
                    '''
                }
            }
        }
    }

    post {
        success { echo "Deployed ${IMAGE_TAG} to EKS cluster ${CLUSTER_NAME}." }
        failure { echo 'Pipeline failed — check the stage logs above.' }
    }
}
