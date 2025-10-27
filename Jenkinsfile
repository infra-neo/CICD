pipeline {
    agent any
    
    tools {
        maven 'Maven 3.9.2'
        jdk 'JDK 17'
    }
    
    environment {
        NEXUS_URL = 'http://nexus:8081'
        SONARQUBE_URL = 'http://sonarqube:9000'
        BUILD_CONFIG = 'build-config.yml'
    }
    
    stages {
        stage('Read Build Config') {
            steps {
                script {
                    echo "Reading build configuration from ${BUILD_CONFIG}"
                    if (fileExists(BUILD_CONFIG)) {
                        def config = readYaml file: BUILD_CONFIG
                        env.JAVA_VERSION = config.java_version ?: '17'
                        env.MAVEN_VERSION = config.maven_version ?: '3.9.2'
                        env.BUILD_TOOL = config.build?.tool ?: 'maven'
                        echo "Java Version: ${env.JAVA_VERSION}"
                        echo "Maven Version: ${env.MAVEN_VERSION}"
                        echo "Build Tool: ${env.BUILD_TOOL}"
                    } else {
                        echo "Warning: ${BUILD_CONFIG} not found. Using defaults."
                    }
                }
            }
        }
        
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo "Building with ${env.BUILD_TOOL}..."
                    if (env.BUILD_TOOL == 'mule-maven-plugin') {
                        sh 'mvn clean package -DskipTests'
                    } else {
                        sh 'mvn clean install -DskipTests'
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'mvn test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                script {
                    echo 'Running SonarQube analysis...'
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            mvn sonar:sonar \
                            -Dsonar.projectKey=${env.JOB_NAME} \
                            -Dsonar.projectName=${env.JOB_NAME} \
                            -Dsonar.host.url=${SONARQUBE_URL}
                        """
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
        
        stage('Deploy to Nexus') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'develop'
                }
            }
            steps {
                echo 'Deploying artifacts to Nexus...'
                withCredentials([usernamePassword(credentialsId: 'nexus-credentials', 
                                                  usernameVariable: 'NEXUS_USER', 
                                                  passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                        mvn deploy -DskipTests \
                        -DaltDeploymentRepository=nexus::default::${NEXUS_URL}/repository/maven-snapshots
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            cleanWs()
        }
    }
}
