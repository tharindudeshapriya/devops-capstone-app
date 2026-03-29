pipeline {
    agent any

    tools {
        maven 'maven3'
    }
    
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        IMAGE_TAG = "v${BUILD_NUMBER}"
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/tharindudeshapriya/devops-capstone-app.git'
            }
        }
        
        stage('Compile') {
            steps {
                sh 'mvn compile'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test -DskipTests=true'
            }
        }
        
        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs --format table -o fs-report.html .'
            }
        }
        
        stage('Code Quality Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    // This MUST remain on a single line to prevent bash trailing space errors!
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar-projectName=GCBank -Dsonar.projectKey=GCBank -Dsonar.java.binaries=target '''
                }
            }
        }
        
        stage('Quality Gate Check') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }
        
        stage('Publish Artifacts') {
            steps {
                // Ensure your Jenkins Managed File ID is exactly 'tharindu'
                withMaven(globalMavenSettingsConfig: 'tharindu', maven: 'maven3', mavenSettingsConfig: '', traceability: true) {
                    sh 'mvn deploy -DskipTests'    
                }
            }
        }
        
        stage('Build and Tag Docker Images') {
            steps {
                sh "docker build -t tmdeshapriya/bankapp:${IMAGE_TAG} ."
            }
        }
        
        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image --format table -o image-report.html tmdeshapriya/bankapp:$IMAGE_TAG'
            }
        }
        
        stage('Push Docker Images') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh "docker push tmdeshapriya/bankapp:$IMAGE_TAG"
                    }
                }
            }
        }
        
        stage('Update manifests file in CD repo') {
            steps {
                script {
                    cleanWs()
                    sh '''
                    # Clone your specific CD repository
                    git clone [https://github.com/tharindudeshapriya/devops-capstone-k8s-manifests.git](https://github.com/tharindudeshapriya/devops-capstone-k8s-manifests.git)
                    
                    cd devops-capstone-k8s-manifests
                    
                    # Search for the old tag and replace it with the new build tag
                    sed -i "s|tmdeshapriya/bankapp:.*|tmdeshapriya/bankapp:${IMAGE_TAG}|" k8s/Manifest.yaml

                    echo "image tag updated"
                    cat k8s/Manifest.yaml

                    # commit and push the changes
                    git config user.name "tharindudeshapriya"
                    git config user.email "tmdeshapriya@gmail.com"
                    git add k8s/Manifest.yaml
                    git commit -m "image tag updated to ${IMAGE_TAG}"
                    '''

                    withCredentials([usernamePassword(credentialsId: 'github-cred', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    sh '''
                    cd devops-capstone-k8s-manifests
                    git remote set-url origin https://$GIT_USER:$GIT_PASS@github.com/tharindudeshapriya/devops-capstone-k8s-manifests.git
                    git push origin main
                    '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            script {
                def jobName = env.JOB_NAME
                def buildNumber = env.BUILD_NUMBER
                def pipelineStatus = currentBuild.result ?: 'UNKNOWN'
                def bannerColor = pipelineStatus.toUpperCase() == 'SUCCESS' ? 'green' : 'red'

                def body = """
                    <html>
                        <body>
                            <div style="border: 4px solid ${bannerColor}; padding: 10px;">
                                <h2>${jobName} - Build #${buildNumber}</h2>
                                <div style="background-color: ${bannerColor}; padding: 10px;">
                                    <h3 style="color: white;">Pipeline Status: ${pipelineStatus.toUpperCase()}</h3>
                                </div>
                                <p>Check the <a href="${env.BUILD_URL}">Console Output</a> for more details.</p>
                            </div>
                        </body>
                    </html>
                """

                emailext(
                    subject: "${jobName} - Build #${buildNumber} - ${pipelineStatus.toUpperCase()}",
                    body: body,
                    to: 'tmdeshapriya@gmail.com',
                    from: 'tmdeshapriya@gmail.com',
                    replyTo: 'tmdeshapriya@gmail.com',
                    mimeType: 'text/html',
                    attachmentsPattern: 'fs-report.html'
                )
            }
        }
    }
}