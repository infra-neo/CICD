# Complete User Guide - CI/CD Environment

## Table of Contents
1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Working with Environments](#working-with-environments)
4. [Security Best Practices](#security-best-practices)
5. [Deployment Workflows](#deployment-workflows)
6. [Version Management](#version-management)
7. [Backup and Restore](#backup-and-restore)
8. [Troubleshooting](#troubleshooting)

## Introduction

This CI/CD environment provides a complete automated pipeline for building, testing, and deploying Java applications to WildFly or JBoss application servers. It includes:

- **Jenkins**: CI/CD orchestration
- **SonarQube**: Code quality and security analysis
- **Nexus**: Artifact and dependency management
- **WildFly**: Modern Jakarta EE application server
- **JBoss**: Legacy application support
- **PostgreSQL**: Database for SonarQube

## Getting Started

### Initial Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd CICD
   ```

2. **Run the setup script**:
   ```bash
   ./setup.sh
   ```

3. **Wait for initialization** (approximately 5-10 minutes)

4. **Access services**:
   - Jenkins: http://localhost:8080 (admin/admin)
   - SonarQube: http://localhost:9000 (admin/admin)
   - Nexus: http://localhost:8081 (admin/[check password])
   - WildFly: http://localhost:8090 (admin/admin)
   - JBoss: http://localhost:8070 (admin/admin)

### First Application Deployment

1. **Use the sample application**:
   ```bash
   cd examples/webapp-sample
   mvn clean package
   docker cp target/*.war wildfly:/opt/jboss/wildfly/standalone/deployments/
   ```

2. **Access your application**:
   ```
   http://localhost:8090/webapp-sample-1.0.0-SNAPSHOT/
   ```

## Working with Environments

### Environment Types

The system supports three environments:

1. **Development (dev)**
   - Debug enabled
   - Verbose logging
   - Quick iteration
   - No quality gates

2. **Staging (staging)**
   - Limited debugging
   - INFO level logging
   - Pre-production testing
   - Quality gates enforced

3. **Production (prod)**
   - No debugging
   - WARN level logging
   - Strict quality gates
   - Performance optimized

### Creating Environment-Specific Properties

1. **Create properties file**:
   ```bash
   mkdir -p config/environments/dev
   cat > config/environments/dev/application.properties << EOF
   app.name=myapp
   app.version=\${APP_VERSION}
   app.environment=development
   
   # Database
   db.url=jdbc:postgresql://postgres:5432/devdb
   db.username=devuser
   db.password=\${DB_PASSWORD_DEV}
   
   # External Services
   api.url=http://dev-api.example.com
   api.key=\${API_KEY_DEV}
   EOF
   ```

2. **Create secrets file** (never commit this!):
   ```bash
   cat > config/environments/dev/secrets.env << EOF
   DB_PASSWORD_DEV=your-dev-password
   API_KEY_DEV=your-dev-api-key
   EOF
   ```

3. **Use in Jenkins pipeline**:
   - Select environment in pipeline parameters
   - Pipeline automatically loads properties
   - Secrets are masked in logs

### Managing Multiple Applications

Each application can have its own configuration:

```
config/environments/
├── dev/
│   ├── app1/
│   │   ├── application.properties
│   │   └── database.properties
│   └── app2/
│       ├── application.properties
│       └── database.properties
├── staging/
│   ├── app1/
│   └── app2/
└── prod/
    ├── app1/
    └── app2/
```

## Security Best Practices

### Never Hardcode Secrets

❌ **Bad**:
```java
String password = "mySecretPassword123";
String apiKey = "sk_live_abc123xyz";
```

✅ **Good**:
```java
String password = System.getenv("DB_PASSWORD");
String apiKey = System.getenv("API_KEY");
```

### Using Environment Variables

1. **In properties files**:
   ```properties
   db.password=${DB_PASSWORD_PROD}
   api.key=${API_KEY_PROD}
   ```

2. **In Jenkins**:
   - Store as Jenkins credentials
   - Reference in pipeline with `withCredentials()`

3. **In Docker Compose**:
   ```yaml
   environment:
     - DB_PASSWORD=${DB_PASSWORD_PROD}
   ```

### Password Scanning

The pipeline automatically scans for hardcoded passwords:

```bash
# This will fail the build
String pass = "password123";

# This is correct
String pass = System.getenv("DB_PASSWORD");
```

To test password scanning:
```bash
cd examples/webapp-sample
# Add a hardcoded password to any Java file
# Run the pipeline - it will fail with security error
```

### Secret Management

1. **Create template from secrets**:
   ```bash
   cp config/secrets.env.template config/secrets.env
   ```

2. **Edit with real values**:
   ```bash
   nano config/secrets.env
   ```

3. **Load in Jenkins**:
   - Use "Credentials" plugin
   - Add as "Secret file" or "Secret text"
   - Reference in pipeline

## Deployment Workflows

### Workflow 1: Standard Git-Based Deployment

1. **Push code to Git**:
   ```bash
   git add .
   git commit -m "My changes"
   git push origin main
   ```

2. **Jenkins automatically**:
   - Detects change
   - Checks out code
   - Runs security scan
   - Builds application
   - Runs tests
   - Analyzes with SonarQube
   - Deploys to Nexus
   - Deploys to WildFly/JBoss

### Workflow 2: ZIP-Based Deployment

For applications without Git:

1. **Create ZIP of source code**:
   ```bash
   zip -r myapp-source.zip src/ pom.xml
   ```

2. **Upload and build**:
   ```bash
   ./upload-source.sh myapp-source.zip dev wildfly
   ```

3. **Script handles**:
   - Extraction
   - Security scanning
   - Building
   - Testing
   - Deployment

### Workflow 3: Manual Maven Build

For local testing:

1. **Build locally**:
   ```bash
   cd examples/webapp-sample
   mvn clean package
   ```

2. **Deploy manually**:
   ```bash
   # To WildFly
   docker cp target/*.war wildfly:/opt/jboss/wildfly/standalone/deployments/
   
   # To JBoss
   docker cp target/*.war jboss:/opt/jboss/wildfly/standalone/deployments/
   ```

### Workflow 4: Jenkins Pipeline with Parameters

1. **Create parameterized job** in Jenkins

2. **Configure parameters**:
   - ENVIRONMENT: dev/staging/prod
   - TARGET_SERVER: wildfly/jboss
   - SKIP_TESTS: true/false
   - FROM_ZIP: true/false

3. **Run with parameters**:
   - Select desired options
   - Click "Build with Parameters"
   - Monitor progress

## Version Management

### Automatic Versioning

Every build gets a unique version:
```
Format: {BUILD_NUMBER}-{TIMESTAMP}
Example: 42-20251025-143022
```

### Version Information in Artifacts

Each WAR file includes `version.properties`:
```properties
VERSION=42-20251025-143022
ENVIRONMENT=production
BUILD_NUMBER=42
BUILD_DATE=2025-10-25T14:30:22Z
GIT_COMMIT=abc123def
GIT_BRANCH=main
BUILT_BY=Jenkins
TARGET_SERVER=wildfly
```

### Retrieving Version Information

From deployed application:
```java
Properties props = new Properties();
props.load(getClass().getClassLoader()
    .getResourceAsStream("version.properties"));
String version = props.getProperty("VERSION");
```

### Version History in Nexus

All versions stored in Nexus:
```
http://localhost:8081/#browse/browse:maven-snapshots
```

Navigate to:
```
com/example/webapp-sample/
├── 1.0.0-42-20251025-143022/
├── 1.0.0-43-20251025-150301/
└── 1.0.0-44-20251025-163045/
```

### Properties Versioning

Configuration files versioned alongside code:
```bash
# Download specific version
curl -O http://nexus:8081/repository/maven-snapshots/\
properties/myapp/42-20251025-143022/\
properties-prod-42-20251025-143022.tar.gz

# Extract
tar xzf properties-prod-42-20251025-143022.tar.gz

# Use
cp properties-42-20251025-143022/* config/environments/prod/
```

## Backup and Restore

### Creating Backups

1. **Full backup**:
   ```bash
   ./backup-restore.sh backup
   ```

2. **What gets backed up**:
   - All environment configurations
   - WildFly and JBoss configurations
   - Jenkins jobs and credentials
   - Nexus configuration
   - SonarQube database
   - Build configurations

3. **Backup location**:
   ```
   backups/backup-20251025_143022.tar.gz
   ```

### Listing Backups

```bash
./backup-restore.sh list
```

Output:
```
Timestamp          | Size    | Date
-------------------+---------+-------------------------
20251025_143022    | 45M     | 2025-10-25 14:30:22
20251024_120000    | 42M     | 2025-10-24 12:00:00
```

### Restoring from Backup

1. **Choose backup**:
   ```bash
   ./backup-restore.sh list
   ```

2. **Restore**:
   ```bash
   ./backup-restore.sh restore 20251025_143022
   ```

3. **Restart services**:
   ```bash
   docker compose restart
   ```

### Backup Schedule

Recommended schedule:
- **Daily**: Development environment
- **Weekly**: Staging environment
- **Before each deployment**: Production environment

Automate with cron:
```bash
# Daily backup at 2 AM
0 2 * * * cd /path/to/CICD && ./backup-restore.sh backup
```

## Troubleshooting

### Service Won't Start

**Problem**: Container fails to start

**Solution**:
```bash
# Check logs
docker logs wildfly

# Check resources
docker stats

# Restart service
docker compose restart wildfly
```

### Application Won't Deploy

**Problem**: WAR file copied but not deploying

**Solution**:
```bash
# Check deployment directory
docker exec wildfly ls -la /opt/jboss/wildfly/standalone/deployments/

# Look for .failed or .error files
docker exec wildfly cat /opt/jboss/wildfly/standalone/deployments/*.failed

# Check server logs
docker logs wildfly --tail 100
```

### Build Fails with Security Error

**Problem**: "Hardcoded passwords detected"

**Solution**:
```bash
# Find the hardcoded password
grep -r "password.*=.*['\"]" src/

# Replace with environment variable
# Before:
String password = "mypass123";

# After:
String password = System.getenv("DB_PASSWORD");
```

### Out of Memory

**Problem**: Services crashing with OOM

**Solution**:
```bash
# Check memory usage
docker stats

# Increase memory in docker-compose.yml
services:
  wildfly:
    environment:
      - JAVA_OPTS=-Xms2048m -Xmx4096m
```

### Nexus Password Lost

**Problem**: Can't access Nexus admin

**Solution**:
```bash
# Get initial password
docker exec nexus cat /nexus-data/admin.password

# Or reset (WARNING: Loses data)
docker compose down -v
docker compose up -d
```

### Jenkins Job Fails

**Problem**: Pipeline fails at specific stage

**Solution**:
```bash
# Check Jenkins logs
docker logs jenkins --tail 200

# Check workspace
docker exec jenkins ls -la /var/jenkins_home/workspace/

# Replay pipeline with debug
# In Jenkins UI: Replay → Edit → Add debug statements
```

### SonarQube Analysis Fails

**Problem**: SonarQube step fails

**Solution**:
```bash
# Check SonarQube is running
curl http://localhost:9000

# Check logs
docker logs sonarqube

# Verify credentials in Jenkins
# Jenkins → Manage Jenkins → Credentials
```

## Advanced Topics

### Custom Build Configurations

Edit `build-config.yml`:
```yaml
java_version: 17
maven_version: 3.9.2

build:
  tool: maven
  packaging: war

security:
  password_scan: true
  mask_credentials: true

appserver:
  type: wildfly
```

### Multi-Stage Pipelines

Create complex workflows:
```groovy
stage('Deploy to Staging') {
    when { branch 'develop' }
    steps {
        // Deploy to staging
    }
}

stage('Approval') {
    when { branch 'main' }
    steps {
        input 'Deploy to production?'
    }
}

stage('Deploy to Production') {
    when { branch 'main' }
    steps {
        // Deploy to production
    }
}
```

### Load Balancing

Run multiple instances:
```yaml
wildfly-1:
  image: quay.io/wildfly/wildfly:latest
  ports:
    - "8091:8080"

wildfly-2:
  image: quay.io/wildfly/wildfly:latest
  ports:
    - "8092:8080"
```

Add nginx for load balancing.

## Support

For additional help:
- Check documentation in `MIGRATION_GUIDE.md`
- Review examples in `examples/`
- Check logs: `docker compose logs [service]`
- Review configuration: `cat build-config.yml`

## Conclusion

This CI/CD environment provides enterprise-grade capabilities for Java application development and deployment. By following this guide, you can:

- Build and test applications automatically
- Deploy to multiple environments safely
- Manage secrets securely
- Track versions comprehensively
- Recover from failures quickly

Happy deploying! 🚀
