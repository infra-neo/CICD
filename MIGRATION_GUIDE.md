# JBoss to WildFly Migration Guide

This guide helps you migrate Java applications from JBoss EAP to WildFly using the automated CI/CD pipeline.

## Table of Contents
1. [Overview](#overview)
2. [Migration Strategy](#migration-strategy)
3. [Prerequisites](#prerequisites)
4. [Step-by-Step Migration](#step-by-step-migration)
5. [Testing Strategy](#testing-strategy)
6. [Deployment Options](#deployment-options)
7. [Troubleshooting](#troubleshooting)

## Overview

The CI/CD environment supports both JBoss EAP and WildFly containers, allowing you to:
- Run both servers simultaneously for testing
- Gradually migrate applications
- Test compatibility before production deployment
- Automate the entire migration process

### Key Differences: JBoss EAP vs WildFly

| Feature | JBoss EAP | WildFly |
|---------|-----------|---------|
| Licensing | Commercial (Red Hat) | Open Source |
| Support | Enterprise Support | Community |
| Release Cycle | Slower, Stable | Faster, Latest Features |
| Jakarta EE | Supported | Fully Supported |
| Java Version | Up to Java 11/17 | Up to Java 17+ |

## Migration Strategy

### Phase 1: Assessment
1. Inventory all JBoss applications
2. Identify dependencies and versions
3. Review Jakarta EE compatibility
4. Document custom configurations

### Phase 2: Preparation
1. Update Maven POM files
2. Replace Java EE with Jakarta EE dependencies
3. Update configuration files
4. Prepare environment-specific properties

### Phase 3: Testing
1. Deploy to WildFly in development environment
2. Run automated tests
3. Perform manual testing
4. Compare behavior with JBoss version

### Phase 4: Migration
1. Deploy to staging for validation
2. Run parallel instances (JBoss + WildFly)
3. Gradually switch traffic to WildFly
4. Monitor and optimize

## Prerequisites

### Infrastructure
- Docker and Docker Compose installed
- At least 4GB RAM available
- Git repository with source code

### Application Requirements
- Java 17 compatible source code
- Maven 3.9+ build configuration
- Jakarta EE 8+ or Jakarta EE 9+ dependencies

## Step-by-Step Migration

### 1. Update Dependencies

Edit your `pom.xml`:

```xml
<!-- Replace Java EE with Jakarta EE -->
<dependency>
    <groupId>jakarta.platform</groupId>
    <artifactId>jakarta.jakartaee-api</artifactId>
    <version>9.1.0</version>
    <scope>provided</scope>
</dependency>

<!-- Update Servlet API -->
<dependency>
    <groupId>jakarta.servlet</groupId>
    <artifactId>jakarta.servlet-api</artifactId>
    <version>5.0.0</version>
    <scope>provided</scope>
</dependency>
```

### 2. Update Imports

Replace Java EE imports with Jakarta EE:

```java
// Old (Java EE)
import javax.servlet.*;
import javax.persistence.*;
import javax.ejb.*;

// New (Jakarta EE)
import jakarta.servlet.*;
import jakarta.persistence.*;
import jakarta.ejb.*;
```

You can automate this with a script:

```bash
find src -name "*.java" -type f -exec sed -i 's/javax\.servlet/jakarta.servlet/g' {} +
find src -name "*.java" -type f -exec sed -i 's/javax\.persistence/jakarta.persistence/g' {} +
find src -name "*.java" -type f -exec sed -i 's/javax\.ejb/jakarta.ejb/g' {} +
```

### 3. Update Configuration Files

#### Update web.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="https://jakarta.ee/xml/ns/jakartaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="https://jakarta.ee/xml/ns/jakartaee 
         https://jakarta.ee/xml/ns/jakartaee/web-app_5_0.xsd"
         version="5.0">
    <!-- Configuration -->
</web-app>
```

#### Update persistence.xml (if using JPA)

```xml
<persistence xmlns="https://jakarta.ee/xml/ns/persistence"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="https://jakarta.ee/xml/ns/persistence
             https://jakarta.ee/xml/ns/persistence/persistence_3_0.xsd"
             version="3.0">
    <!-- Configuration -->
</persistence>
```

### 4. Configure Environment Properties

Create environment-specific files in `config/environments/`:

**dev/application.properties**:
```properties
app.name=my-application
app.version=${APP_VERSION}
app.environment=development
server.type=wildfly
```

**staging/application.properties**:
```properties
app.name=my-application
app.version=${APP_VERSION}
app.environment=staging
server.type=wildfly
```

**prod/application.properties**:
```properties
app.name=my-application
app.version=${APP_VERSION}
app.environment=production
server.type=wildfly
```

### 5. Configure Maven for WildFly

Add WildFly plugin to `pom.xml`:

```xml
<plugin>
    <groupId>org.wildfly.plugins</groupId>
    <artifactId>wildfly-maven-plugin</artifactId>
    <version>4.2.0.Final</version>
    <configuration>
        <hostname>wildfly</hostname>
        <port>9990</port>
        <username>admin</username>
        <password>admin</password>
    </configuration>
</plugin>
```

### 6. Setup CI/CD Pipeline

Copy the enhanced Jenkinsfile:

```bash
cp Jenkinsfile.enhanced Jenkinsfile
```

Commit and push to trigger the pipeline:

```bash
git add .
git commit -m "Migrate to WildFly with CI/CD pipeline"
git push origin main
```

### 7. Configure Jenkins Job

1. Open Jenkins: http://localhost:8080
2. Create new Pipeline job
3. Configure parameters:
   - `ENVIRONMENT`: dev/staging/prod
   - `TARGET_SERVER`: wildfly/jboss
   - `FROM_ZIP`: false (unless using ZIP upload)
4. Point to your Git repository
5. Specify `Jenkinsfile` as script path

## Testing Strategy

### Automated Testing

The pipeline includes:

1. **Unit Tests**: Maven Surefire
2. **Code Quality**: SonarQube analysis
3. **Security Scan**: Password detection
4. **Integration Tests**: Optional

### Manual Testing Checklist

- [ ] Application starts successfully
- [ ] All endpoints are accessible
- [ ] Database connections work
- [ ] Authentication/authorization functions
- [ ] Logging is configured correctly
- [ ] Environment variables are loaded
- [ ] External service integrations work

### Performance Testing

Compare JBoss vs WildFly performance:

```bash
# JBoss
ab -n 1000 -c 10 http://localhost:8070/your-app/

# WildFly
ab -n 1000 -c 10 http://localhost:8090/your-app/
```

## Deployment Options

### Option 1: Automated via Jenkins

Jenkins handles:
- Building the WAR file
- Running tests
- Security scanning
- Deployment to WildFly or JBoss
- Version tracking

### Option 2: Manual Deployment

```bash
# Build
mvn clean package

# Deploy to WildFly
docker cp target/myapp.war wildfly:/opt/jboss/wildfly/standalone/deployments/

# Or use Maven plugin
mvn wildfly:deploy
```

### Option 3: Using Source ZIP

If you have source code in a ZIP file:

1. Upload ZIP to Jenkins workspace
2. Set `FROM_ZIP=true` parameter
3. Pipeline will extract and build

## Parallel Running (Blue-Green Deployment)

Run both JBoss and WildFly simultaneously:

1. Deploy to JBoss on port 8070
2. Deploy to WildFly on port 8090
3. Use load balancer to split traffic
4. Gradually increase WildFly traffic
5. Monitor for issues
6. Complete migration when stable

## Environment-Specific Configuration

### Managing Properties

Each environment has its own configuration:

```
config/environments/
├── dev/
│   ├── application.properties
│   ├── database.properties
│   └── settings.xml
├── staging/
│   ├── application.properties
│   ├── database.properties
│   └── settings.xml
└── prod/
    ├── application.properties
    ├── database.properties
    └── settings.xml
```

### Using Environment Variables for Secrets

Never hardcode passwords! Use environment variables:

```properties
# application.properties
db.password=${DB_PASSWORD_PROD}
api.key=${API_KEY_PROD}
```

Set in Jenkins credentials or Docker environment.

## Version Control

### Artifact Versioning

Every build creates a versioned artifact:
```
myapp-1.0.0-20251025-143022.war
```

Format: `{version}-{date}-{time}.war`

### Properties Versioning

Configuration files are versioned and stored in Nexus:
```
properties-dev-1.0.0-20251025-143022.tar.gz
```

This allows rollback to any previous configuration.

## Rollback Strategy

If migration fails:

1. **Immediate Rollback**:
   ```bash
   # Switch traffic back to JBoss
   # JBoss is still running on port 8070
   ```

2. **Artifact Rollback**:
   ```bash
   # Download previous version from Nexus
   # Deploy to WildFly
   ```

3. **Configuration Rollback**:
   ```bash
   # Download previous properties from Nexus
   # Apply to environment
   ```

## Troubleshooting

### Common Issues

#### Application fails to deploy on WildFly

**Solution**: Check logs
```bash
docker logs wildfly
```

Look for:
- ClassNotFoundException (missing dependencies)
- Namespace issues (Java EE vs Jakarta EE)
- Configuration errors

#### Performance degradation

**Solution**: Adjust JVM settings

Edit `docker-compose.yml`:
```yaml
wildfly:
  environment:
    - JAVA_OPTS=-Xms2048m -Xmx4096m
```

#### Database connection fails

**Solution**: Verify datasource configuration

Check `standalone.xml` or use environment variables:
```properties
db.url=jdbc:postgresql://postgres:5432/mydb
db.username=${DB_USER}
db.password=${DB_PASSWORD}
```

#### Session migration issues

**Solution**: Ensure session serialization

Make session objects implement `Serializable`:
```java
public class UserSession implements Serializable {
    private static final long serialVersionUID = 1L;
    // ...
}
```

## Best Practices

1. **Test Thoroughly**: Always test in dev before staging/prod
2. **Version Everything**: Code, configuration, and properties
3. **Use Environment Variables**: Never hardcode credentials
4. **Monitor Closely**: Watch logs and metrics during migration
5. **Document Changes**: Keep migration notes
6. **Backup Before Migration**: Backup JBoss configuration and data
7. **Plan Rollback**: Always have a rollback plan ready

## Support and Resources

### Official Documentation
- [WildFly Documentation](https://docs.wildfly.org/)
- [Jakarta EE Documentation](https://jakarta.ee/specifications/)
- [Maven Central](https://search.maven.org/)

### Community Support
- WildFly Forums
- Stack Overflow
- Red Hat Developer Portal

## Next Steps

After successful migration:

1. **Optimize Performance**: Tune WildFly configuration
2. **Enhance Monitoring**: Add APM tools
3. **Implement HA**: Setup clustering for high availability
4. **Security Hardening**: Review and enhance security settings
5. **Documentation**: Update team documentation with new procedures

## Conclusion

This automated CI/CD pipeline makes JBoss to WildFly migration:
- **Faster**: Automated builds and deployments
- **Safer**: Automated testing and security scanning
- **Repeatable**: Consistent process for all applications
- **Traceable**: Complete version history and audit trail

Happy migrating! 🚀
