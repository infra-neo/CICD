# CI/CD Stack Completo con Jenkins, SonarQube, Nexus y PostgreSQL

Stack completo de CI/CD usando Docker Compose con Jenkins, SonarQube, Nexus Repository Manager y PostgreSQL, todo corriendo en una sola VM Ubuntu.

## 📋 Tabla de Contenidos

- [Características](#características)
- [Requisitos Previos](#requisitos-previos)
- [Arquitectura](#arquitectura)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Uso](#uso)
- [Pipeline de CI/CD](#pipeline-de-cicd)
- [Aplicación de Ejemplo](#aplicación-de-ejemplo)
- [Troubleshooting](#troubleshooting)

## ✨ Características

- **Jenkins** con plugins preinstalados para CI/CD
  - Docker workflow support
  - SonarQube integration
  - Nexus artifact uploader
  - Maven support
  - Dependency security scanner
  - Configuration as Code (JCasC)
  
- **SonarQube** para análisis de calidad de código
  - Base de datos PostgreSQL dedicada
  - Análisis estático de código
  - Quality Gates configurables
  
- **Nexus Repository Manager** para gestión de artefactos
  - Repositorios Maven (releases y snapshots)
  - Cache de dependencias
  
- **PostgreSQL** como base de datos para SonarQube
  
- **Volúmenes Persistentes** para todos los servicios
  
- **Cache Maven (.m2)** compartido para acelerar builds
  
- **Aplicación Java/Maven de ejemplo** con:
  - Tests unitarios
  - Análisis de seguridad (OWASP Dependency Check)
  - Integración con SonarQube
  - Deploy automático a Nexus

## 🔧 Requisitos Previos

- Ubuntu 20.04 LTS o superior
- Docker Engine 20.10 o superior
- Docker Compose v2.0 o superior
- Mínimo 8GB RAM (recomendado 16GB)
- Mínimo 50GB de espacio en disco

### Instalación de Docker y Docker Compose

```bash
# Actualizar el sistema
sudo apt-get update
sudo apt-get upgrade -y

# Instalar dependencias
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Agregar clave GPG de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Agregar repositorio de Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Verificar instalación
docker --version
docker compose version
```

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                         VM Ubuntu                            │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              Docker Compose Network                     │ │
│  │  ┌──────────┐  ┌───────────┐  ┌───────┐  ┌──────────┐ │ │
│  │  │          │  │           │  │       │  │          │ │ │
│  │  │ Jenkins  │──│ SonarQube │──│ Nexus │  │PostgreSQL│ │ │
│  │  │  :8080   │  │   :9000   │  │ :8081 │  │  :5432   │ │ │
│  │  │          │  │           │  │       │  │          │ │ │
│  │  └────┬─────┘  └─────┬─────┘  └───┬───┘  └────┬─────┘ │ │
│  │       │              │            │           │        │ │
│  │  ┌────┴──────────────┴────────────┴───────────┴─────┐ │ │
│  │  │           Persistent Volumes                      │ │ │
│  │  │  - jenkins-data                                   │ │ │
│  │  │  - maven-cache (.m2)                              │ │ │
│  │  │  - sonarqube-data                                 │ │ │
│  │  │  - nexus-data                                     │ │ │
│  │  │  - postgres-data                                  │ │ │
│  │  └───────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Instalación

1. **Clonar el repositorio**

```bash
git clone https://github.com/infra-neo/CICD.git
cd CICD
```

2. **Configurar parámetros del sistema (importante para SonarQube)**

```bash
# Aumentar límites del sistema para SonarQube
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w fs.file-max=65536

# Hacer cambios permanentes
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=65536" | sudo tee -a /etc/sysctl.conf
```

3. **Iniciar el stack**

```bash
# Construir y levantar todos los servicios
docker compose up -d

# Verificar el estado de los contenedores
docker compose ps

# Ver logs
docker compose logs -f
```

4. **Esperar a que todos los servicios estén listos**

El proceso completo puede tomar de 5 a 10 minutos. Puedes monitorear el progreso:

```bash
# Ver logs de Jenkins
docker compose logs -f jenkins

# Ver logs de SonarQube
docker compose logs -f sonarqube

# Ver logs de Nexus
docker compose logs -f nexus
```

## ⚙️ Configuración

### Acceso a los Servicios

Una vez que todos los servicios estén ejecutándose:

| Servicio | URL | Usuario por Defecto | Contraseña por Defecto |
|----------|-----|---------------------|------------------------|
| Jenkins | http://localhost:8080 | admin | admin123 |
| SonarQube | http://localhost:9000 | admin | admin |
| Nexus | http://localhost:8081 | admin | Ver comando abajo |

**Obtener contraseña de Nexus:**
```bash
docker exec cicd-nexus cat /nexus-data/admin.password
```

### Configuración Inicial de SonarQube

1. Acceder a SonarQube en http://localhost:9000
2. Login con credenciales por defecto (admin/admin)
3. Cambiar la contraseña cuando se solicite
4. Ir a **My Account → Security → Generate Tokens**
5. Crear un token llamado `jenkins-token`
6. Copiar el token generado

### Configuración Inicial de Nexus

1. Acceder a Nexus en http://localhost:8081
2. Hacer clic en "Sign In" 
3. Obtener la contraseña inicial:
   ```bash
   docker exec cicd-nexus cat /nexus-data/admin.password
   ```
4. Completar el asistente de configuración inicial
5. Crear los repositorios necesarios:
   - `maven-releases` (ya existe por defecto)
   - `maven-snapshots` (ya existe por defecto)

### Configuración de Credenciales en Jenkins

1. Acceder a Jenkins en http://localhost:8080
2. Ir a **Manage Jenkins → Credentials → System → Global credentials**
3. Agregar las siguientes credenciales:

   **SonarQube Token:**
   - Kind: Secret text
   - ID: `sonarqube-token`
   - Secret: [token generado en SonarQube]
   
   **Nexus Credentials:**
   - Kind: Username with password
   - ID: `nexus-credentials`
   - Username: admin
   - Password: [contraseña de Nexus]

### Configuración de Maven Settings

Crear archivo `settings.xml` en Jenkins para autenticación con Nexus:

1. Ir a **Manage Jenkins → Managed files → Add a new Config**
2. Seleccionar "Maven settings.xml"
3. ID: `maven-settings`
4. Agregar la configuración de servidores:

```xml
<settings>
  <servers>
    <server>
      <id>nexus-snapshots</id>
      <username>admin</username>
      <password>TU_PASSWORD_NEXUS</password>
    </server>
    <server>
      <id>nexus-releases</id>
      <username>admin</username>
      <password>TU_PASSWORD_NEXUS</password>
    </server>
  </servers>
</settings>
```

## 📦 Uso

### Crear un Pipeline en Jenkins

1. En Jenkins, hacer clic en **New Item**
2. Nombre: `example-app-pipeline`
3. Tipo: **Pipeline**
4. En la sección **Pipeline**:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: URL de tu repositorio
   - Branch: main
   - Script Path: `example-app/Jenkinsfile`
5. Guardar y ejecutar **Build Now**

### Monitorear el Pipeline

El pipeline ejecutará automáticamente las siguientes etapas:

1. **Checkout**: Obtiene el código fuente
2. **Build**: Compila la aplicación
3. **Unit Tests**: Ejecuta pruebas unitarias (`mvn test`)
4. **Security Scan**: Escaneo de vulnerabilidades con OWASP Dependency Check
5. **SonarQube Analysis**: Análisis de calidad de código
6. **Quality Gate**: Verifica umbrales de calidad
7. **Package**: Empaqueta la aplicación
8. **Deploy to Nexus**: Sube el artefacto a Nexus (solo en rama main)

## 🔄 Pipeline de CI/CD

### Jenkinsfile

El `Jenkinsfile` incluido implementa las siguientes mejores prácticas:

- ✅ **Tests unitarios obligatorios**: El pipeline falla si los tests no pasan
- 🔒 **Escaneo de seguridad**: OWASP Dependency Check para vulnerabilidades
- 📊 **Análisis de calidad**: SonarQube con Quality Gates
- 📦 **Cache de Maven**: Reutiliza dependencias para builds más rápidos
- 🚀 **Deploy automático**: Solo en rama main
- 📝 **Reportes**: Tests, seguridad y calidad de código

### build-config.yml

Archivo de configuración centralizado que define:

- Configuración del proyecto
- Comandos de build
- Configuración de testing
- Parámetros de seguridad
- Configuración de SonarQube
- Repositorios de Nexus
- Estrategia de deployment

## 🧪 Aplicación de Ejemplo

La aplicación de ejemplo (`example-app`) incluye:

### Estructura del Proyecto

```
example-app/
├── src/
│   ├── main/
│   │   └── java/
│   │       └── com/
│   │           └── example/
│   │               └── app/
│   │                   └── Calculator.java
│   └── test/
│       └── java/
│           └── com/
│               └── example/
│                   └── app/
│                       └── CalculatorTest.java
├── pom.xml
├── Jenkinsfile
└── build-config.yml
```

### Ejecutar la Aplicación Localmente

```bash
cd example-app

# Compilar
mvn clean compile

# Ejecutar tests
mvn test

# Empaquetar
mvn package

# Ejecutar la aplicación
java -jar target/example-app-1.0.0-SNAPSHOT.jar
```

### Tests Incluidos

- Tests unitarios con JUnit
- Cobertura de código
- Validación de excepciones

## 🔍 Troubleshooting

### Jenkins no inicia

```bash
# Ver logs
docker compose logs jenkins

# Verificar permisos
docker exec -it cicd-jenkins ls -la /var/jenkins_home

# Reiniciar servicio
docker compose restart jenkins
```

### SonarQube no inicia (Error: max virtual memory)

```bash
# Aumentar límite de memoria virtual
sudo sysctl -w vm.max_map_count=262144
```

### Nexus no inicia (Memoria insuficiente)

Editar `docker-compose.yml` y aumentar memoria:

```yaml
environment:
  INSTALL4J_ADD_VM_PARAMS: "-Xms1024m -Xmx1024m"
```

### Pipeline falla en Security Scan

El escaneo de seguridad puede fallar en la primera ejecución debido a la descarga de la base de datos CVE. Es normal y se resolverá en la siguiente ejecución.

### Limpiar volúmenes y empezar de nuevo

```bash
# Detener y eliminar contenedores
docker compose down

# Eliminar volúmenes (CUIDADO: esto borra todos los datos)
docker compose down -v

# Reiniciar
docker compose up -d
```

## 🛠️ Comandos Útiles

```bash
# Ver estado de los servicios
docker compose ps

# Ver logs de todos los servicios
docker compose logs -f

# Ver logs de un servicio específico
docker compose logs -f jenkins

# Detener todos los servicios
docker compose stop

# Reiniciar un servicio específico
docker compose restart jenkins

# Acceder a un contenedor
docker exec -it cicd-jenkins bash

# Ver uso de recursos
docker stats

# Limpiar imágenes no utilizadas
docker image prune -a
```

## 📝 Notas Adicionales

- **Seguridad**: Cambiar todas las contraseñas por defecto en un entorno de producción
- **Backup**: Configurar backups periódicos de los volúmenes persistentes
- **Firewall**: Configurar reglas de firewall para restringir acceso a los servicios
- **SSL/TLS**: Implementar certificados SSL para conexiones seguras
- **Monitoreo**: Considerar agregar herramientas de monitoreo como Prometheus y Grafana

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue o pull request para sugerencias y mejoras.

## 📧 Soporte

Para problemas o preguntas, por favor abre un issue en el repositorio de GitHub.