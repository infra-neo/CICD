# Quick Reference Guide

## Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Jenkins | http://localhost:8080 | admin / admin |
| SonarQube | http://localhost:9000 | admin / admin |
| Nexus | http://localhost:8081 | admin / [generated] |
| WildFly | http://localhost:8090 | admin / admin |
| WildFly Admin | http://localhost:9990 | admin / admin |
| JBoss | http://localhost:8070 | admin / admin |
| JBoss Admin | http://localhost:9970 | admin / admin |

## Common Commands

### Setup and Teardown
```bash
# Initial setup
./setup.sh

# Stop all services
docker compose down

# Stop and remove volumes (CAUTION: deletes data)
docker compose down -v

# Restart all services
docker compose restart

# Restart specific service
docker compose restart wildfly
```

### Viewing Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f wildfly
docker compose logs -f jenkins
docker compose logs -f sonarqube

# Last 100 lines
docker logs wildfly --tail 100
```

### Building Applications
```bash
# From examples directory
cd examples/webapp-sample
mvn clean package

# With tests
mvn clean install

# Skip tests
mvn clean package -DskipTests

# With SonarQube
mvn clean verify sonar:sonar
```

### Deploying Applications
```bash
# To WildFly
docker cp target/*.war wildfly:/opt/jboss/wildfly/standalone/deployments/

# To JBoss
docker cp target/*.war jboss:/opt/jboss/wildfly/standalone/deployments/

# Using Maven plugin
mvn wildfly:deploy

# From ZIP file
./upload-source.sh myapp.zip dev wildfly
```

### Backup and Restore
```bash
# Create backup
./backup-restore.sh backup

# List backups
./backup-restore.sh list

# Restore backup
./backup-restore.sh restore 20251025_143022
```

### Checking Service Status
```bash
# List running containers
docker ps

# Check resource usage
docker stats

# Check specific service health
curl -s http://localhost:8080 && echo "Jenkins is up"
curl -s http://localhost:9000 && echo "SonarQube is up"
curl -s http://localhost:8081 && echo "Nexus is up"
curl -s http://localhost:8090 && echo "WildFly is up"
curl -s http://localhost:8070 && echo "JBoss is up"
```

### Getting Nexus Password
```bash
docker exec nexus cat /nexus-data/admin.password
```

### Accessing Container Shell
```bash
# WildFly
docker exec -it wildfly /bin/bash

# JBoss
docker exec -it jboss /bin/bash

# Jenkins
docker exec -it jenkins /bin/bash

# Nexus
docker exec -it nexus /bin/bash
```

### Checking Deployments
```bash
# WildFly deployments
docker exec wildfly ls -la /opt/jboss/wildfly/standalone/deployments/

# JBoss deployments
docker exec jboss ls -la /opt/jboss/wildfly/standalone/deployments/

# Check deployment status
docker exec wildfly cat /opt/jboss/wildfly/standalone/deployments/*.deployed
```

### Managing Volumes
```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect jenkins_home

# Remove unused volumes (CAUTION)
docker volume prune
```

## File Locations

### Configuration Files
```
config/
├── environments/
│   ├── dev/application.properties
│   ├── staging/application.properties
│   └── prod/application.properties
├── wildfly/setup-admin.sh
├── jboss/setup-admin.sh
└── secrets.env.template
```

### Jenkins Configuration
```
jenkins/init.groovy.d/
├── 01-admin-user.groovy
├── 02-install-plugins.groovy
├── 03-configure-credentials.groovy
├── 04-configure-sonarqube.groovy
├── 05-configure-maven.groovy
└── 06-configure-appserver-credentials.groovy
```

### Example Projects
```
examples/
├── pom.xml (simple example)
├── settings.xml
└── webapp-sample/ (full web app)
    ├── pom.xml
    ├── src/main/java/
    └── src/test/java/
```

## Pipeline Parameters

When creating Jenkins jobs, use these parameters:

| Parameter | Values | Description |
|-----------|--------|-------------|
| ENVIRONMENT | dev, staging, prod | Target environment |
| TARGET_SERVER | wildfly, jboss | Application server |
| SKIP_TESTS | true, false | Skip test execution |
| SKIP_SONAR | true, false | Skip SonarQube analysis |
| FROM_ZIP | true, false | Build from ZIP source |

## Environment Variables

### For Properties Files
```properties
db.password=${DB_PASSWORD_DEV}
api.key=${API_KEY_PROD}
app.version=${APP_VERSION}
```

### For Docker Compose
```yaml
environment:
  - WILDFLY_USER=admin
  - WILDFLY_PASS=admin
  - JAVA_OPTS=-Xms2048m -Xmx4096m
```

## Security Scanning

### Patterns That Will Fail
```java
// These will cause build failure:
String password = "myPassword123";
String apiKey = "sk_live_abc123";
String token = "ghp_xyz123abc";
```

### Correct Usage
```java
// Use environment variables:
String password = System.getenv("DB_PASSWORD");
String apiKey = System.getenv("API_KEY");
String token = System.getenv("AUTH_TOKEN");
```

## Maven Goals

### Basic Goals
```bash
mvn clean           # Clean build directory
mvn compile         # Compile source code
mvn test            # Run tests
mvn package         # Create WAR/JAR
mvn install         # Install to local repo
mvn deploy          # Deploy to Nexus
```

### Combined Goals
```bash
mvn clean install                    # Clean and install
mvn clean package -DskipTests        # Package without tests
mvn clean verify sonar:sonar         # Build and analyze
```

### With Profiles
```bash
mvn clean install -Pdev              # Development profile
mvn clean install -Pproduction       # Production profile
```

## Troubleshooting Quick Fixes

### Service Won't Start
```bash
# Check logs
docker logs [service-name] --tail 50

# Restart service
docker compose restart [service-name]

# Remove and recreate
docker compose down
docker compose up -d
```

### Out of Memory
```bash
# Check memory
docker stats

# Increase in docker-compose.yml
environment:
  - JAVA_OPTS=-Xms2048m -Xmx4096m
```

### Deployment Fails
```bash
# Check deployment directory permissions
docker exec wildfly ls -la /opt/jboss/wildfly/standalone/deployments/

# Check for error files
docker exec wildfly cat /opt/jboss/wildfly/standalone/deployments/*.failed

# Manually undeploy
docker exec wildfly rm /opt/jboss/wildfly/standalone/deployments/myapp.war.failed
```

### Clean Start
```bash
# Complete reset (CAUTION: destroys all data)
docker compose down -v
docker volume prune -f
./setup.sh
```

## Port Reference

| Port | Service | Purpose |
|------|---------|---------|
| 8080 | Jenkins | Web UI |
| 50000 | Jenkins | Agent communication |
| 9000 | SonarQube | Web UI |
| 8081 | Nexus | Web UI |
| 8090 | WildFly | HTTP |
| 9990 | WildFly | Admin Console |
| 8070 | JBoss | HTTP |
| 9970 | JBoss | Admin Console |
| 5432 | PostgreSQL | Database (internal) |

## Version Information

Check versions:
```bash
# Maven
mvn -version

# Docker
docker --version

# Docker Compose
docker compose version

# Java in container
docker exec wildfly java -version
```

## Quick Testing

### Test Jenkins
```bash
curl -s http://localhost:8080/login | grep -q "Jenkins" && echo "✓ Jenkins OK"
```

### Test SonarQube
```bash
curl -s http://localhost:9000 | grep -q "SonarQube" && echo "✓ SonarQube OK"
```

### Test WildFly
```bash
curl -s http://localhost:8090 | grep -q "WildFly" && echo "✓ WildFly OK"
```

### Test Deployment
```bash
# After deploying webapp-sample
curl http://localhost:8090/webapp-sample-1.0.0-SNAPSHOT/ | grep -q "Application is running" && echo "✓ App deployed"
```

## Documentation Links

- [Main README](README.md) - Overview and setup
- [Migration Guide](MIGRATION_GUIDE.md) - JBoss to WildFly migration
- [User Guide](USER_GUIDE.md) - Comprehensive usage guide
- [Quick Start](QUICKSTART.md) - Fast start guide
- [Configuration](CONFIGURATION.md) - Advanced configuration
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues

## Support

For help:
1. Check logs: `docker compose logs -f`
2. Review documentation
3. Check examples: `cd examples/webapp-sample`
4. Test with sample app first
5. Create issue on GitHub

---

**Remember**: Always backup before making changes to production!
```bash
./backup-restore.sh backup
```
