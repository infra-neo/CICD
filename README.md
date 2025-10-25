# CI/CD Environment

Complete CI/CD environment with Jenkins, SonarQube, Nexus, WildFly, and JBoss running in Docker containers.

## 🚀 Quick Start

```bash
git clone <repository-url>
cd CICD
./setup.sh
```

That's it! The script will set up everything automatically.

## 📋 Prerequisites

- Ubuntu Linux (or compatible OS)
- Docker (version 20.10 or later)
- Docker Compose (version 1.29 or later)
- At least 6GB of available RAM (increased for WildFly/JBoss)
- At least 15GB of free disk space

## 🏗️ Architecture

The environment consists of the following services:

### Jenkins
- **Port**: 8080 (web UI), 50000 (agent communication)
- **Default credentials**: admin/admin
- **Features**:
  - Auto-configured with essential plugins
  - Pre-configured Maven 3.9.2
  - Integrated with SonarQube and Nexus
  - Pipeline support with enhanced Jenkinsfile
  - WildFly and JBoss deployment support

### SonarQube
- **Port**: 9000
- **Default credentials**: admin/admin
- **Database**: PostgreSQL 13
- **Features**:
  - Code quality analysis
  - Security vulnerability detection
  - Technical debt tracking
  - Password and secret scanning

### Nexus Repository Manager
- **Port**: 8081
- **Default credentials**: admin/[generated password]
- **Features**:
  - Maven releases repository
  - Maven snapshots repository
  - Artifact storage and distribution
  - Versioned properties storage

### WildFly Application Server
- **Port**: 8090 (HTTP), 9990 (Admin)
- **Default credentials**: admin/admin
- **Features**:
  - Jakarta EE 9+ support
  - Hot deployment
  - Management console
  - Production-ready application server

### JBoss EAP (WildFly-based)
- **Port**: 8070 (HTTP), 9970 (Admin)
- **Default credentials**: admin/admin
- **Features**:
  - Legacy application support
  - Migration testing platform
  - Compatible with WildFly deployments

### PostgreSQL
- **Internal service** (not exposed)
- Used by SonarQube for data persistence

## 📦 What's Included

```
CICD/
├── docker-compose.yml          # Docker Compose configuration
├── setup.sh                    # Automated setup script
├── build-config.yml            # Sample build configuration
├── Jenkinsfile                 # Sample CI/CD pipeline
├── jenkins/
│   └── init.groovy.d/          # Jenkins auto-configuration scripts
│       ├── 01-admin-user.groovy
│       ├── 02-install-plugins.groovy
│       ├── 03-configure-credentials.groovy
│       ├── 04-configure-sonarqube.groovy
│       └── 05-configure-maven.groovy
└── README.md
```

## 🔧 Configuration

### Build Configuration (build-config.yml)

The `build-config.yml` file allows you to configure your project build settings:

```yaml
java_version: 17
maven_version: 3.9.2

build:
  tool: maven  # Options: maven, mule-maven-plugin
  clean_install: true
  skip_tests: false

test:
  enabled: true
  command: mvn test

sonarqube:
  enabled: true
  host_url: http://sonarqube:9000

nexus:
  enabled: true
  url: http://nexus:8081
  repository:
    releases: maven-releases
    snapshots: maven-snapshots
```

### Jenkins Pipeline (Jenkinsfile)

The included Jenkinsfile demonstrates a complete CI/CD pipeline:

1. **Read Build Config**: Loads settings from `build-config.yml`
2. **Checkout**: Gets source code from repository
3. **Build**: Compiles using `mvn clean install` or `mule-maven-plugin`
4. **Test**: Runs `mvn test`
5. **SonarQube Analysis**: Executes `mvn sonar:sonar`
6. **Quality Gate**: Waits for SonarQube quality gate result
7. **Deploy to Nexus**: Uploads artifacts using `mvn deploy`

## 🌐 Accessing Services

Once the setup is complete, access the services at:

- **Jenkins**: http://localhost:8080
- **SonarQube**: http://localhost:9000
- **Nexus**: http://localhost:8081
- **WildFly**: http://localhost:8090 (Admin: http://localhost:9990)
- **JBoss**: http://localhost:8070 (Admin: http://localhost:9970)

### Getting Nexus Password

The Nexus admin password is auto-generated. Retrieve it with:

```bash
docker exec nexus cat /nexus-data/admin.password
```

## 🎯 New Features

### JBoss to WildFly Migration Support
- Side-by-side JBoss and WildFly containers
- Automated migration pipeline
- Parallel testing capabilities
- Comprehensive migration guide (see [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md))

### Enhanced Security
- **Password Detection**: Automatic scanning for hardcoded passwords
- **Secret Masking**: Credentials masked in logs and outputs
- **Environment Variables**: Enforced use of environment variables for secrets
- **Security Templates**: Pre-configured secure credential storage

### Environment-Specific Configuration
- **Multi-Environment Support**: Dev, Staging, Production configurations
- **Property Versioning**: All configurations version-controlled
- **Environment Isolation**: Separate .m2 repositories per environment
- **Configuration Management**: Stored and versioned in Nexus

### Source Code Upload Support
- **ZIP Upload**: Build applications from uploaded ZIP files
- **Automated Extraction**: Pipeline handles extraction and build
- **Local Repository**: Per-application Maven repository support
- **Upload Script**: `upload-source.sh` for easy ZIP deployment

### Advanced Versioning
- **Automatic Versioning**: Build number + timestamp versioning
- **Version Embedding**: Version info embedded in artifacts
- **Properties Versioning**: Configuration files versioned with artifacts
- **Rollback Support**: Easy rollback to any previous version

### Backup and Restore
- **Full Backups**: Complete environment backup capability
- **Selective Restore**: Restore specific components
- **Backup Script**: `backup-restore.sh` for easy backup management
- **Version History**: Complete audit trail of all changes

## 🔐 Security

### Network Isolation
All containers run on an internal bridge network (`cicd-network`) for security.

### Persistent Data
Data is stored in Docker volumes:
- `jenkins_home`: Jenkins configuration and jobs
- `postgres_data`: PostgreSQL database
- `sonarqube_data`: SonarQube data
- `sonarqube_extensions`: SonarQube plugins
- `sonarqube_logs`: SonarQube logs
- `nexus_data`: Nexus repositories and configuration

### Default Credentials

**Jenkins**:
- Username: `admin`
- Password: `admin`

**SonarQube**:
- Username: `admin`
- Password: `admin`

**Nexus**:
- Username: `admin`
- Password: (generated - see above)

> ⚠️ **Important**: Change these default credentials in production!

## 🛠️ Common Operations

### Start Services
```bash
docker-compose up -d
```

### Stop Services
```bash
docker-compose down
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f jenkins
docker-compose logs -f sonarqube
docker-compose logs -f nexus
```

### Restart Services
```bash
docker-compose restart
```

### Remove Everything (including volumes)
```bash
docker-compose down -v
```

## 📝 Using the Pipeline

### 1. Create a Java Web Application

See the example in `examples/webapp-sample/` for a complete WildFly/JBoss-compatible application.

### 2. Configure Environment Properties

Create environment-specific properties:

```
config/environments/
├── dev/application.properties
├── staging/application.properties
└── prod/application.properties
```

Use environment variables for sensitive data:
```properties
db.password=${DB_PASSWORD_PROD}
api.key=${API_KEY_PROD}
```

### 3. Create Jenkins Pipeline Job

1. Go to Jenkins (http://localhost:8080)
2. Click "New Item"
3. Enter a name and select "Pipeline"
4. Configure parameters:
   - `ENVIRONMENT`: dev/staging/prod
   - `TARGET_SERVER`: wildfly/jboss
   - `FROM_ZIP`: Enable if building from ZIP
5. Under "Pipeline", select "Pipeline script from SCM"
6. Configure your repository
7. Specify `Jenkinsfile.enhanced` as the script path
8. Save and run!

### 4. Deploy from Source ZIP

Use the upload script for quick deployments:

```bash
./upload-source.sh myapp-source.zip dev wildfly
```

### 5. Backup Your Configuration

Create regular backups:

```bash
# Create backup
./backup-restore.sh backup

# List backups
./backup-restore.sh list

# Restore from backup
./backup-restore.sh restore 20251025_143022
```

## 🐛 Troubleshooting

### Services Not Starting

Check Docker resources:
```bash
docker stats
```

Ensure you have enough memory (at least 4GB recommended).

### Jenkins Plugins Not Installing

Wait for Jenkins to fully start (may take 2-3 minutes), then check:
```bash
docker-compose logs jenkins
```

### SonarQube Not Accessible

SonarQube needs time to initialize (2-3 minutes). Check status:
```bash
docker-compose logs sonarqube
```

### Nexus Not Starting

Nexus requires significant memory. Check:
```bash
docker-compose logs nexus
```

## 🔄 Updating Services

To update to latest versions:

```bash
docker-compose pull
docker-compose up -d
```

## 📚 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Nexus Repository Manager Documentation](https://help.sonatype.com/repomanager3)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is provided as-is for CI/CD environment setup.