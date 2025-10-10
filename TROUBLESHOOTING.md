# Troubleshooting Guide

Common issues and their solutions for the CI/CD environment.

## Quick Diagnostics

Run these commands first to gather information:

```bash
# Check if services are running
docker ps

# Check service logs
docker compose logs --tail=50

# Check resource usage
docker stats --no-stream

# Check network connectivity
docker network inspect cicd-network
```

## Jenkins Issues

### Issue: Jenkins Won't Start

**Symptoms:**
- Container exits immediately
- Can't access http://localhost:8080

**Solutions:**

1. Check if port 8080 is already in use:
```bash
sudo lsof -i :8080
# or
sudo netstat -tulpn | grep 8080
```

2. Check Jenkins logs:
```bash
docker compose logs jenkins
```

3. Increase memory if needed:
```bash
# Edit docker-compose.yml
environment:
  - JAVA_OPTS=-Djenkins.install.runSetupWizard=false -Xmx2048m
```

4. Reset Jenkins volume:
```bash
docker compose down
docker volume rm cicd_jenkins_home
docker compose up -d
```

### Issue: Jenkins Plugins Not Installing

**Symptoms:**
- Plugins listed in init script not available
- Jenkins shows plugin installation errors

**Solutions:**

1. Wait for Jenkins to fully initialize (2-3 minutes)

2. Check plugin installation logs:
```bash
docker exec jenkins cat /var/jenkins_home/logs/tasks/hudson.diagnosis.ReverseProxySetupMonitor.log
```

3. Manually install plugins via UI:
   - Go to "Manage Jenkins" → "Manage Plugins"
   - Search and install required plugins

4. Check update center connectivity:
```bash
docker exec jenkins curl -I https://updates.jenkins.io/
```

### Issue: "Setup Wizard" Appears Despite Configuration

**Symptom:**
- Jenkins shows setup wizard on first access

**Solution:**

Ensure JAVA_OPTS is set correctly in docker-compose.yml:
```yaml
environment:
  - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
```

### Issue: Jenkins Can't Access SonarQube/Nexus

**Symptoms:**
- Build fails with connection refused
- Can't reach http://sonarqube:9000 or http://nexus:8081

**Solutions:**

1. Verify all services are on same network:
```bash
docker network inspect cicd-network
```

2. Test connectivity from Jenkins container:
```bash
docker exec jenkins curl -I http://sonarqube:9000
docker exec jenkins curl -I http://nexus:8081
```

3. Wait for services to fully start (especially SonarQube takes 2-3 minutes)

## SonarQube Issues

### Issue: SonarQube Won't Start

**Symptoms:**
- Container restarts constantly
- Error about max_map_count

**Solutions:**

1. Increase vm.max_map_count:
```bash
sudo sysctl -w vm.max_map_count=262144
# Make it permanent
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

2. Check PostgreSQL is running:
```bash
docker compose logs postgres
```

3. Increase SonarQube memory:
```yaml
sonarqube:
  environment:
    - SONAR_CE_JAVAOPTS=-Xmx1024m
    - SONAR_WEB_JAVAOPTS=-Xmx1024m
```

### Issue: SonarQube Database Connection Failed

**Symptoms:**
- SonarQube logs show "Could not connect to database"
- PostgreSQL errors in logs

**Solutions:**

1. Verify PostgreSQL is healthy:
```bash
docker exec postgres psql -U sonar -d sonarqube -c "SELECT 1;"
```

2. Check credentials match in docker-compose.yml:
```yaml
postgres:
  environment:
    - POSTGRES_USER=sonar
    - POSTGRES_PASSWORD=sonar
    
sonarqube:
  environment:
    - SONAR_JDBC_USERNAME=sonar
    - SONAR_JDBC_PASSWORD=sonar
```

3. Recreate database:
```bash
docker exec postgres psql -U sonar -c "DROP DATABASE sonarqube;"
docker exec postgres psql -U sonar -c "CREATE DATABASE sonarqube;"
docker compose restart sonarqube
```

### Issue: Can't Login to SonarQube

**Symptom:**
- Default credentials (admin/admin) don't work

**Solution:**

1. SonarQube requires password change on first login
2. Login with admin/admin
3. You'll be prompted to set a new password
4. Update the password in Jenkins credentials if needed

### Issue: SonarQube Analysis Fails

**Symptoms:**
- Maven build fails during sonar:sonar goal
- "Quality Gate" stage fails in Jenkins

**Solutions:**

1. Verify SonarQube token in Jenkins:
```bash
# Check if credential exists
docker exec jenkins cat /var/jenkins_home/credentials.xml | grep sonarqube-token
```

2. Test SonarQube manually:
```bash
mvn sonar:sonar \
  -Dsonar.projectKey=test \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=admin \
  -Dsonar.password=admin
```

3. Check SonarQube server status:
```bash
curl http://localhost:9000/api/system/status
```

## Nexus Issues

### Issue: Nexus Takes Too Long to Start

**Symptom:**
- Nexus not accessible after 5+ minutes

**Solutions:**

1. Check available memory:
```bash
free -h
docker stats nexus
```

2. Reduce Nexus memory requirements:
```yaml
nexus:
  environment:
    - INSTALL4J_ADD_VM_PARAMS=-Xms256m -Xmx512m -XX:MaxDirectMemorySize=273m
```

3. Check Nexus logs:
```bash
docker compose logs nexus | grep -i error
```

### Issue: Can't Get Nexus Admin Password

**Symptom:**
- admin.password file not found

**Solutions:**

1. Wait for Nexus to fully initialize (5-10 minutes)

2. Check if file exists:
```bash
docker exec nexus ls -la /nexus-data/admin.password
```

3. If file doesn't exist, Nexus may have already started. Check logs:
```bash
docker compose logs nexus | grep -i password
```

4. Try default password: admin123

### Issue: Maven Can't Deploy to Nexus

**Symptoms:**
- mvn deploy fails with 401 Unauthorized
- Can't upload artifacts

**Solutions:**

1. Verify credentials in settings.xml:
```xml
<server>
  <id>nexus-snapshots</id>
  <username>admin</username>
  <password>correct-password</password>
</server>
```

2. Ensure repository IDs match:
```xml
<!-- In pom.xml -->
<distributionManagement>
  <snapshotRepository>
    <id>nexus-snapshots</id>  <!-- Must match settings.xml -->
    ...
  </snapshotRepository>
</distributionManagement>
```

3. Enable deployment policy in Nexus:
   - Login to Nexus
   - Go to Repositories → maven-snapshots
   - Check "Allow redeploy"

### Issue: Nexus Repositories Not Created

**Symptom:**
- maven-releases or maven-snapshots don't exist

**Solution:**

Manually create repositories:
1. Login to Nexus (http://localhost:8081)
2. Go to "Server administration and configuration" (gear icon)
3. Click "Repositories" → "Create repository"
4. Select "maven2 (hosted)"
5. Create:
   - Name: maven-releases, Version policy: Release
   - Name: maven-snapshots, Version policy: Snapshot

## Docker Issues

### Issue: "No Space Left on Device"

**Solutions:**

1. Clean up Docker:
```bash
docker system prune -a --volumes
```

2. Check disk usage:
```bash
docker system df
df -h
```

3. Remove old images:
```bash
docker image prune -a
```

### Issue: Container Keeps Restarting

**Solutions:**

1. Check container logs:
```bash
docker logs <container-name>
```

2. Check container health:
```bash
docker inspect <container-name> | grep -A 20 Health
```

3. Remove restart policy temporarily:
```yaml
# In docker-compose.yml, comment out:
# restart: unless-stopped
```

### Issue: Network Communication Fails

**Solutions:**

1. Verify network exists:
```bash
docker network ls | grep cicd
```

2. Recreate network:
```bash
docker compose down
docker network rm cicd-network
docker compose up -d
```

3. Check DNS resolution:
```bash
docker exec jenkins ping sonarqube
docker exec jenkins ping nexus
```

## Build Issues

### Issue: Maven Build Fails - "Project does not have maven-plugin"

**Solution:**

Add Maven wrapper or ensure Maven is installed:
```bash
cd examples
mvn -N io.takari:maven:wrapper
./mvnw clean install
```

### Issue: Java Version Mismatch

**Symptom:**
- "class file version" errors
- UnsupportedClassVersion exceptions

**Solutions:**

1. Verify Java version:
```bash
docker exec jenkins java -version
```

2. Set correct Java version in Jenkinsfile:
```groovy
tools {
    jdk 'JDK 17'  // Must match installed JDK
}
```

3. Update pom.xml:
```xml
<properties>
  <maven.compiler.source>17</maven.compiler.source>
  <maven.compiler.target>17</maven.compiler.target>
</properties>
```

### Issue: Tests Fail During Build

**Solutions:**

1. Skip tests temporarily to verify other stages:
```bash
mvn clean install -DskipTests
```

2. Run tests locally first:
```bash
mvn test
```

3. Check test reports:
```bash
cat target/surefire-reports/*.txt
```

## Performance Issues

### Issue: Services Running Slow

**Solutions:**

1. Check system resources:
```bash
docker stats
htop  # or top
```

2. Increase Docker resources:
   - Docker Desktop: Settings → Resources → Memory (increase to 8GB+)

3. Add resource limits in docker-compose.yml:
```yaml
services:
  jenkins:
    deploy:
      resources:
        limits:
          memory: 2G
```

### Issue: Builds Taking Too Long

**Solutions:**

1. Use build caching:
```groovy
options {
    buildDiscarder(logRotator(numToKeepStr: '10'))
    disableConcurrentBuilds()
    skipDefaultCheckout()
}
```

2. Parallel execution:
```groovy
stage('Test') {
    parallel {
        stage('Unit') { steps { sh 'mvn test' } }
        stage('Integration') { steps { sh 'mvn verify' } }
    }
}
```

3. Optimize Maven:
```bash
mvn clean install -T 4  # Use 4 threads
```

## Data Loss Issues

### Issue: Lost Data After Restart

**Solution:**

Ensure volumes are properly configured:
```bash
# Check volumes
docker volume ls | grep cicd

# Verify volume mounts
docker inspect jenkins | grep -A 10 Mounts
```

### Issue: Need to Restore Backup

**Solution:**

```bash
# Stop services
docker compose down

# Restore volumes
docker run --rm -v cicd_jenkins_home:/data -v $(pwd)/backup:/backup \
  alpine tar xzf /backup/jenkins-backup.tar.gz -C /data

# Start services
docker compose up -d
```

## Getting Help

If your issue isn't listed here:

1. **Check logs in detail:**
```bash
docker compose logs --tail=100 <service-name>
```

2. **Verify configuration:**
```bash
docker compose config
```

3. **Test connectivity:**
```bash
docker exec jenkins curl -v http://sonarqube:9000
docker exec jenkins curl -v http://nexus:8081
```

4. **Get container info:**
```bash
docker inspect <container-name>
```

5. **Complete reset:**
```bash
docker compose down -v
rm -rf jenkins/ examples/target/
./setup.sh
```

## Debug Mode

Enable debug logging:

```yaml
# Jenkins
environment:
  - JAVA_OPTS=-Djenkins.install.runSetupWizard=false -Djava.util.logging.config.file=/var/jenkins_home/logging.properties

# SonarQube
environment:
  - SONAR_LOG_LEVEL=DEBUG

# Maven
sh 'mvn clean install -X'  # Debug mode
```

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Address already in use" | Port conflict | Change port in docker-compose.yml |
| "Cannot connect to Docker daemon" | Docker not running | Start Docker service |
| "No space left on device" | Disk full | Run `docker system prune` |
| "OOMKilled" | Out of memory | Increase Docker memory limit |
| "Network not found" | Network deleted | Run `docker compose down && docker compose up` |
| "Volume not found" | Volume deleted | Restore from backup or start fresh |
| "Permission denied" | Wrong permissions | Run `chmod +x setup.sh` |

## Useful Commands Reference

```bash
# Start everything
docker compose up -d

# Stop everything
docker compose down

# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f jenkins

# Restart a service
docker compose restart jenkins

# Execute command in container
docker exec -it jenkins bash

# Check service status
docker compose ps

# Remove everything including volumes
docker compose down -v

# Update images
docker compose pull
docker compose up -d
```
