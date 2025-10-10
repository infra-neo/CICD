# Guía de Configuración Inicial - CI/CD Stack

Esta guía te llevará paso a paso por la configuración inicial completa del stack CI/CD.

## Tabla de Contenidos

1. [Preparación del Sistema](#1-preparación-del-sistema)
2. [Instalación de Docker](#2-instalación-de-docker)
3. [Iniciar el Stack](#3-iniciar-el-stack)
4. [Configuración de SonarQube](#4-configuración-de-sonarqube)
5. [Configuración de Nexus](#5-configuración-de-nexus)
6. [Configuración de Jenkins](#6-configuración-de-jenkins)
7. [Crear tu Primer Pipeline](#7-crear-tu-primer-pipeline)
8. [Verificación](#8-verificación)

---

## 1. Preparación del Sistema

### Requisitos Mínimos

- Ubuntu 20.04 LTS o superior
- 8GB RAM (recomendado 16GB)
- 50GB espacio en disco
- CPU con al menos 4 cores

### Actualizar el Sistema

```bash
sudo apt-get update
sudo apt-get upgrade -y
```

---

## 2. Instalación de Docker

### Instalar Docker Engine

```bash
# Instalar dependencias
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Agregar clave GPG de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Agregar repositorio
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Aplicar cambios (cerrar y abrir sesión o ejecutar)
newgrp docker

# Verificar instalación
docker --version
docker compose version
```

---

## 3. Iniciar el Stack

### Clonar el Repositorio

```bash
git clone https://github.com/infra-neo/CICD.git
cd CICD
```

### Ejecutar Script de Inicio

```bash
# El script configurará automáticamente los parámetros del sistema
sudo ./start.sh
```

**Nota:** El script configurará:
- `vm.max_map_count=262144` (requerido por SonarQube)
- `fs.file-max=65536`
- Iniciará todos los contenedores

### Monitorear el Inicio

```bash
# Ver logs de todos los servicios
docker compose logs -f

# Ver estado de los contenedores
docker compose ps

# Verificar salud de los servicios
./health-check.sh
```

**Tiempo estimado de inicio:** 5-10 minutos

---

## 4. Configuración de SonarQube

### Acceso Inicial

1. Abrir navegador: http://localhost:9000
2. Credenciales por defecto:
   - Usuario: `admin`
   - Contraseña: `admin`

### Configuración

1. **Cambiar Contraseña**
   - Se solicitará cambiar la contraseña al primer login
   - Usar una contraseña segura

2. **Generar Token de Acceso**
   - Ir a: **My Account** → **Security** → **Generate Tokens**
   - Nombre del token: `jenkins-token`
   - Click en **Generate**
   - **IMPORTANTE:** Copiar el token, lo necesitarás para Jenkins

   Ejemplo: `squ_1234567890abcdef1234567890abcdef12345678`

3. **Crear Quality Gate (Opcional)**
   - Ir a: **Quality Gates**
   - Puede usar el Quality Gate por defecto "Sonar way"

### Verificación

```bash
# Test de conectividad
curl -u admin:TU_NUEVA_CONTRASEÑA http://localhost:9000/api/system/status
```

---

## 5. Configuración de Nexus

### Acceso Inicial

1. Abrir navegador: http://localhost:8081
2. Click en **Sign In**

### Obtener Contraseña Inicial

```bash
docker exec cicd-nexus cat /nexus-data/admin.password
```

Copiar la contraseña mostrada.

### Wizard de Configuración

1. **Login**
   - Usuario: `admin`
   - Contraseña: (la obtenida del comando anterior)

2. **Setup Wizard**
   - Click en **Next**
   - Ingresar nueva contraseña segura
   - **IMPORTANTE:** Guardar esta contraseña

3. **Anonymous Access**
   - Seleccionar: **Disable anonymous access**
   - Click en **Next** y **Finish**

### Verificar Repositorios

Los siguientes repositorios Maven ya deberían existir:
- `maven-central` (proxy)
- `maven-releases` (hosted)
- `maven-snapshots` (hosted)
- `maven-public` (group)

**Ruta:** Administration → Repository → Repositories

---

## 6. Configuración de Jenkins

### Acceso Inicial

1. Abrir navegador: http://localhost:8080
2. Credenciales (configuradas via JCasC):
   - Usuario: `admin`
   - Contraseña: `admin123`

**IMPORTANTE:** Cambiar contraseña en producción

### Agregar Credenciales

#### 6.1 Token de SonarQube

1. Ir a: **Manage Jenkins** → **Credentials**
2. Click en **(global)** → **Add Credentials**
3. Configurar:
   - Kind: `Secret text`
   - Scope: `Global`
   - Secret: [El token de SonarQube que copiaste]
   - ID: `sonarqube-token`
   - Description: `SonarQube Access Token`
4. Click en **Create**

#### 6.2 Credenciales de Nexus

1. En la misma sección de Credentials
2. **Add Credentials**
3. Configurar:
   - Kind: `Username with password`
   - Scope: `Global`
   - Username: `admin`
   - Password: [Contraseña de Nexus]
   - ID: `nexus-credentials`
   - Description: `Nexus Repository Credentials`
4. Click en **Create**

### Configurar SonarQube Server

1. Ir a: **Manage Jenkins** → **System**
2. Buscar sección **SonarQube servers**
3. Click en **Add SonarQube**
4. Configurar:
   - Name: `SonarQube`
   - Server URL: `http://sonarqube:9000`
   - Server authentication token: Seleccionar `sonarqube-token`
5. **Save**

### Configurar Maven Settings (Opcional)

1. Ir a: **Manage Jenkins** → **Managed files**
2. Click en **Add a new Config**
3. Seleccionar: **Maven settings.xml**
4. ID: `maven-settings`
5. Contenido: Ver archivo `maven-settings-template.xml`
6. **Submit**

---

## 7. Crear tu Primer Pipeline

### Opción A: Pipeline desde Git

1. En Jenkins, click en **New Item**
2. Nombre: `example-app-pipeline`
3. Tipo: **Pipeline**
4. Click **OK**

5. En la configuración:
   - Sección **Pipeline**:
     - Definition: `Pipeline script from SCM`
     - SCM: `Git`
     - Repository URL: URL de tu repo Git (o fork del repo CICD)
     - Branch: `*/main`
     - Script Path: `example-app/Jenkinsfile`
   
6. **Save**

### Opción B: Pipeline Inline (para pruebas)

1. En la configuración del Pipeline
2. Sección **Pipeline**:
   - Definition: `Pipeline script`
   - Script: Copiar contenido de `example-app/Jenkinsfile`

3. **Save**

### Ejecutar el Pipeline

1. Click en **Build Now**
2. Ver progreso en **Build History**
3. Click en el número de build para ver detalles
4. Ver **Console Output** para logs detallados

### Etapas del Pipeline

El pipeline ejecutará:
1. ✅ Checkout del código
2. ✅ Compilación (Maven compile)
3. ✅ Tests unitarios (mvn test)
4. ✅ Escaneo de seguridad (OWASP Dependency Check)
5. ✅ Análisis SonarQube
6. ✅ Quality Gate
7. ✅ Empaquetado (mvn package)
8. ✅ Deploy a Nexus (solo rama main)

---

## 8. Verificación

### Verificar Jenkins

```bash
# Test API de Jenkins
curl -u admin:admin123 http://localhost:8080/api/json
```

### Verificar SonarQube

1. Ir a: http://localhost:9000
2. Ver el proyecto `example-app` en el dashboard
3. Revisar métricas de calidad de código

### Verificar Nexus

1. Ir a: http://localhost:8081
2. Click en **Browse**
3. Seleccionar repositorio `maven-snapshots`
4. Verificar que existe el artefacto `com/example/example-app`

### Verificar Volúmenes Persistentes

```bash
# Listar volúmenes
docker volume ls | grep cicd

# Debería mostrar:
# cicd_jenkins-data
# cicd_maven-cache
# cicd_nexus-data
# cicd_postgres-data
# cicd_sonarqube-data
# cicd_sonarqube-extensions
# cicd_sonarqube-logs
```

### Script de Health Check

```bash
./health-check.sh
```

Este script verificará:
- ✅ Estado de todos los contenedores
- ✅ Conectividad a puertos
- ✅ Configuración del sistema
- ✅ Volúmenes persistentes
- ✅ Uso de recursos

---

## Troubleshooting Común

### Pipeline falla en "Security Scan"

**Problema:** Primera ejecución del dependency check puede fallar.

**Solución:** 
```bash
# La base de datos CVE se descarga en el primer run
# Esperar y ejecutar nuevamente
```

### SonarQube no inicia

**Problema:** Error de memoria virtual.

**Solución:**
```bash
sudo sysctl -w vm.max_map_count=262144
docker compose restart sonarqube
```

### Nexus consume mucha memoria

**Problema:** Nexus usa mucha RAM.

**Solución:** Editar `docker-compose.yml`:
```yaml
environment:
  INSTALL4J_ADD_VM_PARAMS: "-Xms512m -Xmx512m"
```

### Jenkins no puede conectarse a SonarQube

**Problema:** Error de conexión en pipeline.

**Solución:**
1. Verificar que el token de SonarQube esté configurado
2. Verificar URL en Jenkins: debe ser `http://sonarqube:9000`
3. Reiniciar Jenkins: `docker compose restart jenkins`

---

## Próximos Pasos

1. **Personalizar el Pipeline**
   - Modificar `example-app/Jenkinsfile` según tus necesidades
   - Agregar más stages (integración continua, deploy, etc.)

2. **Configurar Notificaciones**
   - Email
   - Slack
   - Microsoft Teams

3. **Seguridad**
   - Cambiar todas las contraseñas por defecto
   - Configurar SSL/TLS
   - Implementar autenticación SSO

4. **Backup**
   - Configurar backup automático de volúmenes
   - Script de respaldo periódico

5. **Monitoreo**
   - Agregar Prometheus y Grafana
   - Configurar alertas

---

## Recursos Adicionales

- [Documentación de Jenkins](https://www.jenkins.io/doc/)
- [Documentación de SonarQube](https://docs.sonarqube.org/)
- [Documentación de Nexus](https://help.sonatype.com/repomanager3)
- [Pipeline Syntax Reference](https://www.jenkins.io/doc/book/pipeline/syntax/)

---

## Soporte

Para problemas o preguntas:
- Revisar el README.md principal
- Ejecutar `./health-check.sh`
- Ver logs: `docker compose logs -f`
- Abrir un issue en GitHub
