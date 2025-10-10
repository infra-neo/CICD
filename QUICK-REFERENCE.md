# Quick Reference - CI/CD Stack

## Comandos Esenciales

### Gestión del Stack

```bash
# Iniciar el stack completo
sudo ./start.sh

# Detener el stack
./stop.sh
# o
docker compose stop

# Reiniciar el stack
docker compose restart

# Ver estado de los servicios
docker compose ps

# Ver logs
docker compose logs -f                    # Todos los servicios
docker compose logs -f jenkins            # Solo Jenkins
docker compose logs -f sonarqube          # Solo SonarQube
docker compose logs -f nexus              # Solo Nexus

# Verificar salud del sistema
./health-check.sh

# Detener y eliminar todo (CUIDADO: borra datos)
docker compose down -v
```

### Acceso a los Servicios

| Servicio | URL | Usuario | Contraseña |
|----------|-----|---------|------------|
| Jenkins | http://localhost:8080 | admin | admin123 |
| SonarQube | http://localhost:9000 | admin | admin |
| Nexus | http://localhost:8081 | admin | Ver comando abajo |

```bash
# Obtener contraseña de Nexus
docker exec cicd-nexus cat /nexus-data/admin.password
```

### Comandos Docker Útiles

```bash
# Acceder a un contenedor
docker exec -it cicd-jenkins bash
docker exec -it cicd-sonarqube bash
docker exec -it cicd-nexus bash
docker exec -it cicd-postgres bash

# Ver uso de recursos
docker stats

# Ver volúmenes
docker volume ls | grep cicd

# Inspeccionar un volumen
docker volume inspect cicd_jenkins-data

# Limpiar recursos no usados
docker system prune -a
```

### Maven en el Stack

```bash
# Ejecutar Maven en Jenkins container
docker exec cicd-jenkins mvn -version

# Ver cache de Maven
docker exec cicd-jenkins ls -la /root/.m2/repository

# Limpiar cache de Maven
docker exec cicd-jenkins rm -rf /root/.m2/repository/*
```

## Estructura de Archivos

```
CICD/
├── docker-compose.yml              # Configuración principal del stack
├── start.sh                        # Script de inicio
├── stop.sh                         # Script de parada
├── health-check.sh                 # Script de verificación
├── README.md                       # Documentación principal
├── SETUP-GUIDE.md                  # Guía de configuración paso a paso
├── QUICK-REFERENCE.md              # Esta guía rápida
├── maven-settings-template.xml     # Template para Maven settings
├── .gitignore                      # Archivos ignorados por Git
│
├── jenkins/                        # Configuración de Jenkins
│   ├── Dockerfile                  # Imagen personalizada de Jenkins
│   ├── plugins.txt                 # Lista de plugins
│   └── jenkins-casc.yml            # Configuration as Code
│
└── example-app/                    # Aplicación Java de ejemplo
    ├── src/                        # Código fuente
    │   ├── main/java/...
    │   └── test/java/...
    ├── pom.xml                     # Configuración Maven
    ├── Jenkinsfile                 # Pipeline de CI/CD
    └── build-config.yml            # Configuración del build
```

## Pipeline Stages

```
┌─────────────┐
│  Checkout   │  Obtiene el código desde Git
└──────┬──────┘
       │
┌──────▼──────┐
│    Build    │  Compila la aplicación (mvn compile)
└──────┬──────┘
       │
┌──────▼──────┐
│ Unit Tests  │  Ejecuta tests (mvn test)
└──────┬──────┘
       │
┌──────▼──────────┐
│ Security Scan   │  OWASP Dependency Check
└──────┬──────────┘
       │
┌──────▼─────────────┐
│ SonarQube Analysis │  Análisis de calidad
└──────┬─────────────┘
       │
┌──────▼───────────┐
│  Quality Gate    │  Verifica umbrales
└──────┬───────────┘
       │
┌──────▼──────┐
│   Package   │  Empaqueta JAR (mvn package)
└──────┬──────┘
       │
┌──────▼─────────────┐
│ Deploy to Nexus    │  Sube artefacto (solo main)
└────────────────────┘
```

## Variables de Entorno

### En Jenkins Pipeline

```groovy
environment {
    MAVEN_OPTS = '-Dmaven.repo.local=/root/.m2/repository'
    SONAR_TOKEN = credentials('sonarqube-token')
    NEXUS_CREDENTIALS = credentials('nexus-credentials')
}
```

### En Docker Compose

Ver archivo `docker-compose.yml` para configuración completa.

## IDs de Credenciales

Configurar en Jenkins → Manage Jenkins → Credentials:

| ID | Tipo | Descripción |
|----|------|-------------|
| `sonarqube-token` | Secret text | Token de acceso a SonarQube |
| `nexus-credentials` | Username/Password | Credenciales de Nexus |

## Puertos Utilizados

| Servicio | Puerto Interno | Puerto Externo |
|----------|---------------|----------------|
| Jenkins | 8080 | 8080 |
| Jenkins Agent | 50000 | 50000 |
| SonarQube | 9000 | 9000 |
| Nexus | 8081 | 8081 |
| PostgreSQL | 5432 | - (interno) |

## Volúmenes Persistentes

| Volumen | Contenido | Tamaño Aprox |
|---------|-----------|--------------|
| `jenkins-data` | Configuración y jobs de Jenkins | ~2-5 GB |
| `maven-cache` | Dependencias Maven (.m2) | ~500 MB - 2 GB |
| `sonarqube-data` | Datos de SonarQube | ~1-3 GB |
| `nexus-data` | Artefactos almacenados | Crece con uso |
| `postgres-data` | Base de datos PostgreSQL | ~500 MB |

## Configuración de Sistema

Para SonarQube (requerido):

```bash
# Temporal
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w fs.file-max=65536

# Permanente
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=65536" | sudo tee -a /etc/sysctl.conf
```

## Troubleshooting Rápido

### Jenkins no inicia
```bash
docker compose logs jenkins
docker compose restart jenkins
```

### SonarQube error de memoria
```bash
sudo sysctl -w vm.max_map_count=262144
docker compose restart sonarqube
```

### Limpiar y empezar de nuevo
```bash
docker compose down -v
sudo ./start.sh
```

### Ver contraseña de Nexus
```bash
docker exec cicd-nexus cat /nexus-data/admin.password
```

### Pipeline falla en primera ejecución
```bash
# Normal - dependency check descarga base de datos CVE
# Ejecutar nuevamente el pipeline
```

## URLs de API

### Jenkins
```bash
# API JSON
curl -u admin:admin123 http://localhost:8080/api/json

# Crear job
curl -u admin:admin123 -X POST http://localhost:8080/createItem?name=test-job \
  --data-binary @config.xml -H "Content-Type:text/xml"
```

### SonarQube
```bash
# Status
curl http://localhost:9000/api/system/status

# Projects
curl -u admin:password http://localhost:9000/api/projects/search
```

### Nexus
```bash
# Status
curl -u admin:password http://localhost:8081/service/rest/v1/status

# Repositories
curl -u admin:password http://localhost:8081/service/rest/v1/repositories
```

## Recursos de Ayuda

- Ver logs completos: `docker compose logs -f`
- Health check: `./health-check.sh`
- Guía completa: Ver `SETUP-GUIDE.md`
- README principal: Ver `README.md`

## Respaldo y Restauración

### Backup
```bash
# Backup de volúmenes
docker run --rm -v cicd_jenkins-data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/jenkins-backup.tar.gz -C /data .

docker run --rm -v cicd_nexus-data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/nexus-backup.tar.gz -C /data .
```

### Restore
```bash
# Restore de volúmenes
docker run --rm -v cicd_jenkins-data:/data -v $(pwd):/backup \
  ubuntu bash -c "cd /data && tar xzf /backup/jenkins-backup.tar.gz"
```

## Actualizaciones

### Actualizar imágenes
```bash
docker compose pull
docker compose up -d
```

### Actualizar un servicio específico
```bash
docker compose pull jenkins
docker compose up -d jenkins
```

## Seguridad

### Cambiar contraseñas por defecto

1. **Jenkins**: Manage Jenkins → Security → Update Password
2. **SonarQube**: My Account → Security → Change Password  
3. **Nexus**: Administration → Security → Users → admin → Change Password

### Habilitar HTTPS (producción)

Usar un reverse proxy como Nginx o Traefik con Let's Encrypt.

## Performance

### Optimizar para menos RAM
```yaml
# En docker-compose.yml
nexus:
  environment:
    INSTALL4J_ADD_VM_PARAMS: "-Xms256m -Xmx512m"
```

### Limpiar espacio
```bash
# Limpiar builds antiguos en Jenkins
# Ir a: Manage Jenkins → System Information → Delete old builds

# Limpiar cache de Docker
docker system prune -a

# Limpiar dependency check cache
docker exec cicd-jenkins rm -rf /tmp/dependency-check-data
```
