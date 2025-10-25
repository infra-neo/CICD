# Sample Web Application

This is a sample Java web application designed for deployment to WildFly or JBoss EAP servers through the CI/CD pipeline.

## Features

- Jakarta EE 9+ compatible
- Servlet-based web application
- Maven build with automated tests
- SonarQube integration for code quality
- Nexus integration for artifact management
- Environment-specific configuration support
- Automated deployment to WildFly/JBoss

## Building the Application

### Prerequisites
- Java 17 or later
- Maven 3.9.2 or later
- Docker and Docker Compose (for local testing)

### Build Commands

```bash
# Clean and build
mvn clean install

# Run tests
mvn test

# Run with SonarQube analysis
mvn clean verify sonar:sonar

# Package for deployment
mvn clean package

# Deploy to Nexus
mvn deploy

# Deploy to WildFly (requires server running)
mvn wildfly:deploy
```

## Project Structure

```
webapp-sample/
├── pom.xml                          # Maven configuration
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/webapp/
│   │   │       └── HelloServlet.java    # Main servlet
│   │   └── webapp/
│   │       └── WEB-INF/
│   │           └── web.xml              # Web application descriptor
│   └── test/
│       └── java/
│           └── com/example/webapp/
│               └── HelloServletTest.java # Unit tests
└── README.md                        # This file
```

## Deployment

### Using Jenkins Pipeline

1. Push code to your Git repository
2. Jenkins will automatically:
   - Checkout source code
   - Scan for security issues (hardcoded passwords)
   - Build the application
   - Run unit tests
   - Perform SonarQube analysis
   - Check quality gates
   - Version the artifact
   - Deploy to Nexus
   - Deploy to WildFly or JBoss based on configuration

### Manual Deployment to WildFly

```bash
# Build the WAR file
mvn clean package

# Copy to WildFly deployment directory
docker cp target/webapp-sample-1.0.0-SNAPSHOT.war wildfly:/opt/jboss/wildfly/standalone/deployments/

# Or use WildFly Maven Plugin
mvn wildfly:deploy
```

### Manual Deployment to JBoss

```bash
# Build the WAR file
mvn clean package

# Copy to JBoss deployment directory
docker cp target/webapp-sample-1.0.0-SNAPSHOT.war jboss:/opt/jboss/wildfly/standalone/deployments/
```

## Environment Configuration

The application supports environment-specific configurations:

- **Development** (`dev`): Debug enabled, verbose logging
- **Staging** (`staging`): Limited debugging, INFO logging
- **Production** (`prod`): No debugging, WARN logging

Environment properties are located in:
```
config/environments/
├── dev/
│   └── application.properties
├── staging/
│   └── application.properties
└── prod/
    └── application.properties
```

## Testing Locally

### Start the CI/CD Stack

```bash
cd ../../
./setup.sh
```

### Access Services

- **Application on WildFly**: http://localhost:8090/webapp-sample-1.0.0-SNAPSHOT/
- **Application on JBoss**: http://localhost:8070/webapp-sample-1.0.0-SNAPSHOT/
- **WildFly Admin Console**: http://localhost:9990 (admin/admin)
- **JBoss Admin Console**: http://localhost:9970 (admin/admin)
- **Jenkins**: http://localhost:8080 (admin/admin)
- **SonarQube**: http://localhost:9000 (admin/admin)
- **Nexus**: http://localhost:8081 (admin/[generated])

## Security Features

The pipeline includes:

1. **Password Scanning**: Detects hardcoded passwords in source code
2. **Credential Masking**: Uses Jenkins credentials for sensitive data
3. **Environment Variables**: Passwords stored as environment variables
4. **SonarQube Security**: Security vulnerability detection

## Version Control

Every build is versioned with:
- Build number
- Timestamp
- Git commit hash
- Git branch
- Environment
- Target server

Version information is embedded in the WAR file as `version.properties`.

## Nexus Repository

Artifacts are stored in Nexus with complete version tracking:
- **Maven artifacts**: WAR files with full dependency information
- **Properties packages**: Versioned configuration files
- **Build metadata**: Complete build information

## Migration from JBoss to WildFly

This project demonstrates migration patterns:

1. Use Jakarta EE APIs (compatible with both)
2. Test on both servers during development
3. Use same deployment pipeline for both
4. Gradually migrate applications from JBoss to WildFly

## Troubleshooting

### Application not deploying
- Check server logs: `docker logs wildfly` or `docker logs jboss`
- Verify WAR file is valid: `jar tf target/*.war`
- Check deployment directory has write permissions

### Tests failing
- Ensure Java 17 is being used: `mvn -version`
- Check test logs: `cat target/surefire-reports/*.txt`

### SonarQube analysis fails
- Verify SonarQube is running: `docker ps | grep sonarqube`
- Check SonarQube logs: `docker logs sonarqube`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `mvn test`
5. Submit a pull request

## License

This is a sample application for demonstration purposes.
