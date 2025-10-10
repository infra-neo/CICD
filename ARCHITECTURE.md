# Arquitectura del CI/CD Stack

## Diagrama de Arquitectura General

```
╔════════════════════════════════════════════════════════════════════════╗
║                          Ubuntu VM / Host                               ║
║                                                                         ║
║  ┌─────────────────────────────────────────────────────────────────┐   ║
║  │                    Docker Bridge Network                         │   ║
║  │                        (cicd-network)                            │   ║
║  │                                                                  │   ║
║  │  ┌───────────────┐    ┌──────────────┐    ┌────────────────┐   │   ║
║  │  │               │    │              │    │                │   │   ║
║  │  │   Jenkins     │◄───┤  SonarQube   │    │   PostgreSQL   │   │   ║
║  │  │               │    │              │◄───┤                │   │   ║
║  │  │  Port: 8080   │    │ Port: 9000   │    │   Port: 5432   │   │   ║
║  │  │               │    │              │    │                │   │   ║
║  │  └───────┬───────┘    └──────────────┘    └────────────────┘   │   ║
║  │          │                                                      │   ║
║  │          │                                                      │   ║
║  │          │            ┌──────────────┐                         │   ║
║  │          │            │              │                         │   ║
║  │          └───────────►│    Nexus     │                         │   ║
║  │                       │              │                         │   ║
║  │                       │ Port: 8081   │                         │   ║
║  │                       │              │                         │   ║
║  │                       └──────────────┘                         │   ║
║  │                                                                 │   ║
║  └─────────────────────────────────────────────────────────────────┘   ║
║                                                                         ║
║  ┌─────────────────────────────────────────────────────────────────┐   ║
║  │                   Persistent Volumes                             │   ║
║  │  ┌─────────────┬──────────────┬────────────┬─────────────────┐  │   ║
║  │  │ jenkins-    │ sonarqube-   │  nexus-    │   postgres-     │  │   ║
║  │  │ data        │ data         │  data      │   data          │  │   ║
║  │  │             │              │            │                 │  │   ║
║  │  │ - Jobs      │ - Analysis   │ - Artifacts│ - SonarQube DB  │  │   ║
║  │  │ - Config    │ - Quality    │ - Libs     │                 │  │   ║
║  │  │ - History   │   Gates      │            │                 │  │   ║
║  │  └─────────────┴──────────────┴────────────┴─────────────────┘  │   ║
║  │                                                                  │   ║
║  │  ┌──────────────────────────────────────────────────────────┐   │   ║
║  │  │             maven-cache (/root/.m2)                      │   │   ║
║  │  │  - Cached dependencies                                   │   │   ║
║  │  │  - Speeds up builds                                      │   │   ║
║  │  └──────────────────────────────────────────────────────────┘   │   ║
║  └─────────────────────────────────────────────────────────────────┘   ║
╚════════════════════════════════════════════════════════════════════════╝
```

## Flujo de Integración Continua

```
┌──────────────┐
│   Developer  │
│  commits code│
└──────┬───────┘
       │
       │ git push
       ▼
┌────────────────────────────────────────────────────────────────────┐
│                          JENKINS PIPELINE                           │
│                                                                     │
│  Step 1: Checkout                                                  │
│  ┌──────────────────────────────────────────┐                      │
│  │ - Clone repository                       │                      │
│  │ - Checkout specific branch               │                      │
│  └──────────────────────────────────────────┘                      │
│                    ▼                                                │
│  Step 2: Build                                                     │
│  ┌──────────────────────────────────────────┐                      │
│  │ mvn clean compile                        │                      │
│  │ Uses: maven-cache volume                 │                      │
│  └──────────────────────────────────────────┘                      │
│                    ▼                                                │
│  Step 3: Unit Tests                                                │
│  ┌──────────────────────────────────────────┐                      │
│  │ mvn test                                 │                      │
│  │ Generates: JUnit reports                 │                      │
│  └──────────────────────────────────────────┘                      │
│                    ▼                                                │
│  Step 4: Security Scan                                             │
│  ┌──────────────────────────────────────────┐                      │
│  │ OWASP Dependency Check                   │────────┐             │
│  │ Scans for CVEs                           │        │             │
│  └──────────────────────────────────────────┘        │             │
│                    ▼                                  │             │
│  Step 5: SonarQube Analysis                          │             │
│  ┌──────────────────────────────────────────┐        │             │
│  │ Code quality metrics                     │───┐    │             │
│  │ Coverage, duplications, bugs             │   │    │             │
│  └──────────────────────────────────────────┘   │    │             │
│                    ▼                             │    │             │
│  Step 6: Quality Gate                           │    │             │
│  ┌──────────────────────────────────────────┐   │    │             │
│  │ Check SonarQube thresholds               │   │    │             │
│  │ Pass/Fail decision                       │   │    │             │
│  └──────────────────────────────────────────┘   │    │             │
│                    ▼                             │    │             │
│  Step 7: Package                                 │    │             │
│  ┌──────────────────────────────────────────┐   │    │             │
│  │ mvn package                              │   │    │             │
│  │ Creates JAR artifact                     │   │    │             │
│  └──────────────────────────────────────────┘   │    │             │
│                    ▼                             │    │             │
│  Step 8: Deploy (main branch only)              │    │             │
│  ┌──────────────────────────────────────────┐   │    │             │
│  │ Upload to Nexus Repository               │───┼────┼─────┐       │
│  │ Maven snapshots or releases              │   │    │     │       │
│  └──────────────────────────────────────────┘   │    │     │       │
│                                                  │    │     │       │
└──────────────────────────────────────────────────┼────┼─────┼───────┘
                                                   │    │     │
                    ┌──────────────────────────────┘    │     │
                    ▼                                   │     │
            ┌───────────────┐                           │     │
            │   SonarQube   │◄──────────────────────────┘     │
            │   Dashboard   │                                 │
            └───────────────┘                                 │
                    │                                         │
                    │ Quality Reports                         │
                    ▼                                         │
            ┌───────────────┐                                 │
            │  Developers   │                                 │
            └───────────────┘                                 │
                                                              │
                    ┌─────────────────────────────────────────┘
                    ▼
            ┌───────────────┐
            │     Nexus     │
            │  Repository   │
            └───────────────┘
                    │
                    │ Artifacts ready
                    │ for deployment
                    ▼
            ┌───────────────┐
            │   Production  │
            │  Environment  │
            └───────────────┘
```

## Comunicación entre Servicios

```
Jenkins (cicd-jenkins)
   │
   ├─► SonarQube (cicd-sonarqube:9000)
   │   - Envía código para análisis
   │   - Recibe Quality Gate status
   │   - Autenticación via token
   │
   ├─► Nexus (cicd-nexus:8081)
   │   - Sube artifacts (JAR, WAR, etc.)
   │   - Descarga dependencias (proxy)
   │   - Autenticación via credentials
   │
   └─► Docker Socket (/var/run/docker.sock)
       - Para ejecutar Docker commands
       - Build de imágenes Docker

SonarQube (cicd-sonarqube)
   │
   └─► PostgreSQL (cicd-postgres:5432)
       - Almacena análisis de código
       - Quality Gates
       - Configuración

Nexus (cicd-nexus)
   │
   └─► File System (volume)
       - Almacena artifacts
       - Cache de proxies
       - Blobs storage
```

## Modelo de Datos

### Jenkins
```
jenkins-data/
├── jobs/                    # Definiciones de jobs
│   └── example-app-pipeline/
│       ├── config.xml
│       └── builds/
│           ├── 1/
│           ├── 2/
│           └── ...
├── plugins/                 # Plugins instalados
├── users/                   # Usuarios y credenciales
└── secrets/                 # Secrets encriptados

maven-cache/
└── repository/              # Dependencias Maven
    ├── org/
    ├── com/
    └── ...
```

### SonarQube
```
sonarqube-data/
├── es7/                     # ElasticSearch index
├── ce/                      # Compute Engine queue
└── temp/

PostgreSQL almacena:
- Proyectos y análisis
- Quality Profiles
- Quality Gates
- Configuración
```

### Nexus
```
nexus-data/
├── blobs/                   # Artifact storage
│   ├── default/
│   └── ...
├── db/                      # OrientDB
└── keystores/               # SSL certificates
```

## Puertos y Networking

### Puertos Expuestos al Host

| Puerto | Servicio | Propósito |
|--------|----------|-----------|
| 8080 | Jenkins | Web UI y API |
| 50000 | Jenkins | Agent communication |
| 9000 | SonarQube | Web UI y API |
| 8081 | Nexus | Web UI y API |

### Puertos Internos (Docker Network)

| Puerto | Servicio | Propósito |
|--------|----------|-----------|
| 5432 | PostgreSQL | Database connection |

### Red Docker

- **Nombre:** cicd-network
- **Driver:** bridge
- **Subnet:** Asignado automáticamente por Docker
- **DNS:** Los servicios se resuelven por nombre de contenedor

## Volúmenes y Persistencia

### Estrategia de Almacenamiento

```
Host Machine
└── Docker Volumes (generalmente en /var/lib/docker/volumes/)
    ├── cicd_jenkins-data
    │   - Tamaño inicial: ~500MB
    │   - Crecimiento: ~1-5GB con uso
    │   - Contiene: Jobs, configuración, build history
    │
    ├── cicd_maven-cache
    │   - Tamaño inicial: ~100MB
    │   - Crecimiento: ~500MB-2GB
    │   - Contiene: Dependencies cache
    │
    ├── cicd_sonarqube-data
    │   - Tamaño inicial: ~200MB
    │   - Crecimiento: ~1-3GB
    │   - Contiene: Análisis, índices
    │
    ├── cicd_nexus-data
    │   - Tamaño inicial: ~500MB
    │   - Crecimiento: Variable (artifacts)
    │   - Contiene: Artifacts, proxy cache
    │
    └── cicd_postgres-data
        - Tamaño inicial: ~100MB
        - Crecimiento: ~500MB-1GB
        - Contiene: SonarQube database
```

## Escalabilidad

### Escalado Horizontal (Futuro)

```
┌─────────────────────────────────────────────┐
│         Load Balancer (Nginx/HAProxy)        │
└─────────────┬───────────────────────────────┘
              │
    ┌─────────┴─────────┐
    ▼                   ▼
┌─────────┐        ┌─────────┐
│Jenkins  │        │Jenkins  │
│Master 1 │        │Master 2 │
└────┬────┘        └────┬────┘
     │                  │
     └────────┬─────────┘
              ▼
      ┌──────────────┐
      │ Shared NFS   │
      │ or GlusterFS │
      └──────────────┘
```

### Recursos Recomendados por Escala

| Escala | RAM | CPU | Disco |
|--------|-----|-----|-------|
| Desarrollo (1-5 users) | 8GB | 4 cores | 50GB |
| Pequeña (5-20 users) | 16GB | 8 cores | 100GB |
| Media (20-50 users) | 32GB | 16 cores | 250GB |
| Grande (50+ users) | 64GB+ | 32 cores | 500GB+ |

## Seguridad

### Capas de Seguridad

```
1. Network Layer
   ├── Docker Bridge Network (aislamiento)
   └── Firewall rules (host)

2. Application Layer
   ├── Jenkins: RBAC, credenciales encriptadas
   ├── SonarQube: Tokens, permisos de proyecto
   └── Nexus: Repositorios privados, LDAP

3. Data Layer
   ├── Volúmenes con permisos restrictivos
   └── PostgreSQL: Autenticación por contraseña

4. Transport Layer
   └── HTTPS (requiere configuración adicional)
```

### Mejoras de Seguridad Recomendadas

1. **Implementar HTTPS**
   - Usar reverse proxy (Nginx/Traefik)
   - Certificados SSL de Let's Encrypt

2. **Autenticación Centralizada**
   - LDAP/Active Directory
   - OAuth2/SAML

3. **Secrets Management**
   - HashiCorp Vault
   - AWS Secrets Manager

4. **Network Policies**
   - Limitar comunicación entre servicios
   - Segmentación de red

## Monitoreo y Observabilidad

### Métricas Clave

```
Jenkins:
- Build queue length
- Build success rate
- Build duration
- Agent availability

SonarQube:
- Projects analyzed
- Quality Gate pass rate
- Technical debt

Nexus:
- Storage usage
- Download/Upload rate
- Repository size

System:
- CPU usage
- Memory usage
- Disk I/O
- Network traffic
```

### Stack de Monitoreo Sugerido

```
┌─────────────┐
│  Prometheus │◄─── Metrics from all services
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Grafana   │◄─── Dashboards y alertas
└─────────────┘
```

## Backup y Disaster Recovery

### Estrategia de Backup

```
Daily Backups:
├── jenkins-data       (incremental)
├── nexus-data        (incremental)
└── postgres-data     (full dump)

Weekly Backups:
└── Full backup de todos los volúmenes

Retention:
├── Daily: 7 days
├── Weekly: 4 weeks
└── Monthly: 12 months
```

### Recovery Time Objectives

- **RTO (Recovery Time):** < 2 horas
- **RPO (Recovery Point):** < 24 horas

