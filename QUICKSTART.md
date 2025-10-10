# Quick Start Guide

## 1. Clone and Setup (30 seconds)

```bash
git clone <repository-url>
cd CICD
./setup.sh
```

The setup script will:
- ✅ Stop any existing containers
- ✅ Start all services (Jenkins, SonarQube, Nexus, PostgreSQL)
- ✅ Wait for services to be ready
- ✅ Display access information

## 2. Access Services (Immediately after setup)

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| Jenkins | http://localhost:8080 | admin | admin |
| SonarQube | http://localhost:9000 | admin | admin |
| Nexus | http://localhost:8081 | admin | See below* |

*Get Nexus password:
```bash
docker exec nexus cat /nexus-data/admin.password
```

## 3. Test with Example Project (2 minutes)

```bash
cd examples

# Build the project
mvn clean install

# Run tests
mvn test

# Run SonarQube analysis
mvn sonar:sonar -Dsonar.login=admin -Dsonar.password=admin

# Deploy to Nexus (after configuring settings.xml)
mvn deploy -s settings.xml
```

## 4. Create Your First Jenkins Pipeline (5 minutes)

1. Open Jenkins: http://localhost:8080
2. Click "New Item"
3. Enter name: "sample-pipeline"
4. Select "Pipeline"
5. Under "Pipeline" section:
   - Definition: "Pipeline script from SCM"
   - SCM: Git
   - Repository URL: (your git repo URL)
   - Script Path: `Jenkinsfile`
6. Click "Save"
7. Click "Build Now"

## 5. View Results

### Jenkins
- Build status and logs: http://localhost:8080/job/sample-pipeline/

### SonarQube
- Code quality dashboard: http://localhost:9000/projects

### Nexus
- Deployed artifacts: http://localhost:8081/#browse/browse:maven-snapshots

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    CI/CD Environment                     │
│                   (Docker Network: cicd-network)         │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Jenkins    │  │  SonarQube   │  │    Nexus     │  │
│  │   :8080      │  │   :9000      │  │    :8081     │  │
│  │              │  │              │  │              │  │
│  │ - Build      │  │ - Quality    │  │ - Artifacts  │  │
│  │ - Test       │  │   Analysis   │  │   Storage    │  │
│  │ - Deploy     │  │ - Security   │  │ - Repository │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                  │          │
│         │                 │                  │          │
│         │          ┌──────┴───────┐          │          │
│         │          │  PostgreSQL  │          │          │
│         │          │   (Internal) │          │          │
│         │          │              │          │          │
│         │          │ - Sonar DB   │          │          │
│         │          └──────────────┘          │          │
│         │                                     │          │
│         └─────────────────┬──────────────────┘          │
│                           │                              │
│                    Maven Pipeline                        │
│         mvn clean install → test → sonar → deploy       │
└─────────────────────────────────────────────────────────┘

Host Machine
├── Port 8080  → Jenkins
├── Port 9000  → SonarQube  
└── Port 8081  → Nexus
```

## Pipeline Flow

```
1. Developer commits code
        ↓
2. Jenkins detects change (via webhook or polling)
        ↓
3. Jenkinsfile Pipeline Starts
        ↓
   ┌────────────────────────────────────┐
   │ Read build-config.yml              │
   │ (Java version, Maven version, etc) │
   └────────────┬───────────────────────┘
                ↓
   ┌────────────────────────────────────┐
   │ Checkout Source Code               │
   └────────────┬───────────────────────┘
                ↓
   ┌────────────────────────────────────┐
   │ Build: mvn clean install           │
   └────────────┬───────────────────────┘
                ↓
   ┌────────────────────────────────────┐
   │ Test: mvn test                     │
   └────────────┬───────────────────────┘
                ↓
   ┌────────────────────────────────────┐
   │ SonarQube: mvn sonar:sonar         │
   │ (Code quality & security analysis) │
   └────────────┬───────────────────────┘
                ↓
   ┌────────────────────────────────────┐
   │ Quality Gate Check                 │
   │ (Pass/Fail from SonarQube)         │
   └────────────┬───────────────────────┘
                ↓
   ┌────────────────────────────────────┐
   │ Deploy: mvn deploy                 │
   │ (Upload artifacts to Nexus)        │
   └────────────┬───────────────────────┘
                ↓
4. Pipeline Complete
   - Artifacts in Nexus
   - Quality report in SonarQube
   - Build logs in Jenkins
```

## Troubleshooting

### Services Won't Start
```bash
# Check Docker resources
docker stats

# View logs
docker compose logs jenkins
docker compose logs sonarqube
docker compose logs nexus
```

### Need to Reset Everything
```bash
# Stop and remove all data
docker compose down -v

# Start fresh
./setup.sh
```

### Can't Access Jenkins
Wait 2-3 minutes after startup. Jenkins needs time to initialize.

### SonarQube Shows Error
SonarQube needs PostgreSQL to be ready first. Wait 2-3 minutes.

### Nexus Taking Too Long
Nexus requires significant memory. Ensure you have at least 4GB RAM available.

## Next Steps

1. ✅ Environment is running
2. Configure your project's `pom.xml` with Nexus deployment settings
3. Add `build-config.yml` to your project
4. Create a `Jenkinsfile` in your project root
5. Create a Jenkins pipeline job pointing to your repository
6. Push code and watch the automated CI/CD pipeline!

## Additional Features

### Auto-configured in Jenkins:
- ✅ Admin user (admin/admin)
- ✅ Essential plugins (Git, Maven, SonarQube, Nexus, Pipeline)
- ✅ Maven 3.9.2 installation
- ✅ SonarQube server connection
- ✅ Nexus credentials

### Persistent Data:
All data is stored in Docker volumes and persists across restarts:
- `jenkins_home` - Jenkins jobs and configuration
- `sonarqube_data` - SonarQube analysis data
- `nexus_data` - Maven artifacts
- `postgres_data` - Database

## Support

For issues or questions, refer to:
- Main README.md
- Service logs: `docker compose logs <service-name>`
- Docker status: `docker ps`
