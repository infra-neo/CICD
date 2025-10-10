# Configuration Guide

## Overview

This document provides detailed configuration instructions for customizing the CI/CD environment.

## Jenkins Configuration

### Changing Admin Credentials

Edit `jenkins/init.groovy.d/01-admin-user.groovy`:

```groovy
hudsonRealm.createAccount("your-username", "your-password")
```

### Adding More Plugins

Edit `jenkins/init.groovy.d/02-install-plugins.groovy`:

```groovy
def plugins = [
    "git",
    "workflow-aggregator",
    // Add your plugins here
    "slack",
    "email-ext",
    "docker-plugin"
]
```

### Custom Maven Version

Edit `jenkins/init.groovy.d/05-configure-maven.groovy`:

```groovy
def mavenInstaller = new Maven.MavenInstaller("3.9.3")  // Change version
def maven = new Maven.MavenInstallation(
    "Maven 3.9.3",  // Change name
    null,
    [installSourceProperty]
)
```

### Adding Java Installations

Create `jenkins/init.groovy.d/06-configure-jdk.groovy`:

```groovy
import jenkins.model.Jenkins
import hudson.model.JDK
import hudson.tools.InstallSourceProperty

def instance = Jenkins.getInstance()
def jdkDesc = instance.getDescriptor("hudson.model.JDK")

def jdkInstaller = new JDK.DescriptorImpl.FileOnMasterInstaller("/usr/lib/jvm/java-17-openjdk-amd64")
def installSourceProperty = new InstallSourceProperty([jdkInstaller])

def jdk = new JDK(
    "JDK 17",
    "/usr/lib/jvm/java-17-openjdk-amd64",
    [installSourceProperty]
)

jdkDesc.setInstallations(jdk)
jdkDesc.save()

println "JDK configured"
```

## SonarQube Configuration

### Changing Database Credentials

Edit `docker-compose.yml`:

```yaml
postgres:
  environment:
    - POSTGRES_USER=your-username
    - POSTGRES_PASSWORD=your-password
    - POSTGRES_DB=sonarqube

sonarqube:
  environment:
    - SONAR_JDBC_URL=jdbc:postgresql://postgres:5432/sonarqube
    - SONAR_JDBC_USERNAME=your-username
    - SONAR_JDBC_PASSWORD=your-password
```

### Custom SonarQube Properties

Create `sonarqube/conf/sonar.properties`:

```properties
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.jdbc.url=jdbc:postgresql://postgres:5432/sonarqube
sonar.jdbc.username=sonar
sonar.jdbc.password=sonar

# Custom settings
sonar.web.context=/sonar
sonar.ce.javaOpts=-Xmx512m
```

Mount in `docker-compose.yml`:

```yaml
sonarqube:
  volumes:
    - ./sonarqube/conf:/opt/sonarqube/conf
```

### Quality Profiles and Gates

SonarQube quality profiles can be configured via:
1. Web UI: http://localhost:9000/profiles
2. API: Use SonarQube REST API
3. Backup/Restore: Export from one instance, import to another

## Nexus Configuration

### Pre-configure Repositories

Create `nexus/nexus-config.groovy`:

```groovy
repository.createMavenHosted('maven-releases')
repository.createMavenHosted('maven-snapshots', 'SNAPSHOT')
repository.createMavenProxy('maven-central', 'https://repo1.maven.org/maven2/')
repository.createMavenGroup('maven-public', ['maven-releases', 'maven-snapshots', 'maven-central'])
```

### Custom Nexus Settings

Edit `docker-compose.yml`:

```yaml
nexus:
  environment:
    - INSTALL4J_ADD_VM_PARAMS=-Xms1024m -Xmx1024m -XX:MaxDirectMemorySize=546m
    - NEXUS_CONTEXT=nexus
```

## Docker Compose Customization

### Resource Limits

Add resource constraints:

```yaml
jenkins:
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 2G
      reservations:
        cpus: '1'
        memory: 1G
```

### Health Checks

Add health checks:

```yaml
jenkins:
  healthcheck:
    test: ["CMD-SHELL", "curl -f http://localhost:8080 || exit 1"]
    interval: 30s
    timeout: 10s
    retries: 5
    start_period: 60s
```

### Custom Networks

Create isolated networks:

```yaml
networks:
  jenkins-network:
    driver: bridge
  sonarqube-network:
    driver: bridge
  nexus-network:
    driver: bridge
```

## Build Configuration (build-config.yml)

### Full Configuration Example

```yaml
---
# Project Information
project:
  name: my-awesome-project
  version: 1.0.0

# Java Configuration
java_version: 17
java_opts: "-Xmx2048m -Xms512m"

# Maven Configuration
maven_version: 3.9.2
maven_opts: "-Xmx1024m"

# Build Settings
build:
  tool: maven  # Options: maven, mule-maven-plugin, gradle
  clean_install: true
  skip_tests: false
  profiles:
    - production
    - optimize

# Test Configuration
test:
  enabled: true
  command: mvn test
  coverage: true
  report_path: target/site/jacoco

# SonarQube Configuration
sonarqube:
  enabled: true
  host_url: http://sonarqube:9000
  project_key: ${env.JOB_NAME}
  project_name: ${env.JOB_NAME}
  exclusions:
    - "**/test/**"
    - "**/generated/**"
  coverage_exclusions:
    - "**/dto/**"
    - "**/model/**"

# Nexus Configuration
nexus:
  enabled: true
  url: http://nexus:8081
  repository:
    releases: maven-releases
    snapshots: maven-snapshots
  credentials_id: nexus-credentials

# Deployment
deployment:
  enabled: true
  environments:
    - dev
    - staging
    - production
  strategy: rolling

# Notifications
notifications:
  email:
    enabled: true
    recipients:
      - team@example.com
  slack:
    enabled: false
    channel: "#builds"

# Additional Maven Goals
maven:
  goals:
    - clean
    - compile
    - test
    - package
    - sonar:sonar
    - deploy
  properties:
    skipTests: false
    maven.test.failure.ignore: false
```

## Pipeline Configuration

### Custom Jenkinsfile with Mule Maven Plugin

```groovy
pipeline {
    agent any
    
    tools {
        maven 'Maven 3.9.2'
    }
    
    environment {
        MULE_VERSION = '4.4.0'
    }
    
    stages {
        stage('Build Mule Application') {
            steps {
                sh """
                    mvn clean package -DskipTests \
                    -Dmule.version=${MULE_VERSION}
                """
            }
        }
        
        stage('Deploy to Anypoint') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'anypoint-credentials',
                    usernameVariable: 'ANYPOINT_USER',
                    passwordVariable: 'ANYPOINT_PASS'
                )]) {
                    sh """
                        mvn mule:deploy \
                        -Danypoint.username=${ANYPOINT_USER} \
                        -Danypoint.password=${ANYPOINT_PASS}
                    """
                }
            }
        }
    }
}
```

### Parallel Test Execution

```groovy
stage('Test') {
    parallel {
        stage('Unit Tests') {
            steps {
                sh 'mvn test -Punit-tests'
            }
        }
        stage('Integration Tests') {
            steps {
                sh 'mvn verify -Pintegration-tests'
            }
        }
        stage('Security Tests') {
            steps {
                sh 'mvn verify -Psecurity-tests'
            }
        }
    }
}
```

## Environment Variables

### Jenkins Environment Variables

Set in `docker-compose.yml`:

```yaml
jenkins:
  environment:
    - JENKINS_OPTS=--prefix=/jenkins
    - JAVA_OPTS=-Djenkins.install.runSetupWizard=false -Xmx2048m
    - TRY_UPGRADE_IF_NO_MARKER=true
```

### Application-specific Variables

Create `.env` file:

```env
JENKINS_VERSION=lts
SONARQUBE_VERSION=community
NEXUS_VERSION=latest
POSTGRES_VERSION=13

# Ports
JENKINS_PORT=8080
SONARQUBE_PORT=9000
NEXUS_PORT=8081

# Credentials
JENKINS_USER=admin
JENKINS_PASS=admin
SONAR_USER=admin
SONAR_PASS=admin
```

Reference in `docker-compose.yml`:

```yaml
version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:${JENKINS_VERSION:-lts}
    ports:
      - "${JENKINS_PORT:-8080}:8080"
```

## Security Hardening

### Enable HTTPS (Optional)

Create SSL certificates:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout jenkins.key -out jenkins.crt
```

Mount and configure in Jenkins:

```yaml
jenkins:
  volumes:
    - ./certs:/certs
  environment:
    - JENKINS_OPTS=--httpPort=-1 --httpsPort=8443 --httpsCertificate=/certs/jenkins.crt --httpsPrivateKey=/certs/jenkins.key
```

### Restrict Network Access

```yaml
networks:
  cicd-network:
    driver: bridge
    internal: true  # No external access
    
  public-network:
    driver: bridge

services:
  jenkins:
    networks:
      - cicd-network
      - public-network
```

## Backup and Restore

### Backup Script

Create `backup.sh`:

```bash
#!/bin/bash

BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup Jenkins
docker exec jenkins tar czf /tmp/jenkins-backup.tar.gz /var/jenkins_home
docker cp jenkins:/tmp/jenkins-backup.tar.gz $BACKUP_DIR/

# Backup Nexus
docker exec nexus tar czf /tmp/nexus-backup.tar.gz /nexus-data
docker cp nexus:/tmp/nexus-backup.tar.gz $BACKUP_DIR/

# Backup SonarQube database
docker exec postgres pg_dump -U sonar sonarqube > $BACKUP_DIR/sonarqube.sql

echo "Backup completed in $BACKUP_DIR"
```

### Restore Script

Create `restore.sh`:

```bash
#!/bin/bash

BACKUP_DIR=$1

# Restore Jenkins
docker cp $BACKUP_DIR/jenkins-backup.tar.gz jenkins:/tmp/
docker exec jenkins tar xzf /tmp/jenkins-backup.tar.gz -C /

# Restore Nexus
docker cp $BACKUP_DIR/nexus-backup.tar.gz nexus:/tmp/
docker exec nexus tar xzf /tmp/nexus-backup.tar.gz -C /

# Restore SonarQube database
docker exec -i postgres psql -U sonar sonarqube < $BACKUP_DIR/sonarqube.sql

docker compose restart

echo "Restore completed"
```

## Performance Tuning

### PostgreSQL

Create `postgres/postgresql.conf`:

```conf
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 1310kB
min_wal_size = 1GB
max_wal_size = 4GB
```

### SonarQube

```yaml
sonarqube:
  environment:
    - SONAR_CE_JAVAOPTS=-Xmx1024m -Xms256m
    - SONAR_WEB_JAVAOPTS=-Xmx1024m -Xms256m
```

## Monitoring

### Prometheus + Grafana Integration

Add to `docker-compose.yml`:

```yaml
prometheus:
  image: prom/prometheus
  volumes:
    - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    - prometheus_data:/prometheus
  ports:
    - "9090:9090"
  networks:
    - cicd-network

grafana:
  image: grafana/grafana
  ports:
    - "3000:3000"
  volumes:
    - grafana_data:/var/lib/grafana
  networks:
    - cicd-network
```

## Support

For additional configuration help:
- Check service logs: `docker compose logs <service>`
- Review official documentation
- Open an issue in the repository
