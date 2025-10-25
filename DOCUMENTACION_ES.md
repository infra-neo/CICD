# Documentación en Español - Entorno CI/CD

## Resumen del Proyecto

Este proyecto automatiza completamente la creación de un entorno CI/CD usando contenedores Docker en lugar de máquinas virtuales, basado en las recomendaciones de [cicd-pipeline-mvn-nexus-sonar-jenkins-install](https://github.com/ovusike/cicd-pipeline-mvn-nexus-sonar-jenkins-install).

## Servicios Implementados

### Infraestructura Base
- **Jenkins**: Orquestación de CI/CD (puerto 8080)
- **SonarQube**: Análisis de calidad de código (puerto 9000)
- **Nexus**: Repositorio de artefactos Maven (puerto 8081)
- **PostgreSQL**: Base de datos para SonarQube

### Servidores de Aplicaciones
- **WildFly**: Servidor de aplicaciones moderno Jakarta EE (puerto 8090)
- **JBoss EAP**: Soporte para aplicaciones legacy (puerto 8070)

## Características Principales

### 1. Migración de JBoss a WildFly
✅ Contenedores paralelos de JBoss y WildFly  
✅ Capacidad de pruebas simultáneas  
✅ Documentación completa de migración  
✅ Scripts automatizados de despliegue

### 2. Gestión de Ambientes
Soporte completo para múltiples ambientes:
- **Desarrollo (dev)**: Depuración habilitada, logs verbosos
- **Staging (staging)**: Pre-producción, pruebas de integración
- **Producción (prod)**: Configuración optimizada, sin depuración

Propiedades específicas por ambiente en:
```
config/environments/
├── dev/application.properties
├── staging/application.properties
└── prod/application.properties
```

### 3. Seguridad Mejorada

#### Detección de Contraseñas
El pipeline escanea automáticamente código fuente para detectar:
- Contraseñas hardcodeadas
- Claves API expuestas
- Tokens de autenticación en código

❌ **Esto falla el build**:
```java
String password = "myPassword123";
String apiKey = "sk_live_abc123";
```

✅ **Uso correcto**:
```java
String password = System.getenv("DB_PASSWORD");
String apiKey = System.getenv("API_KEY");
```

#### Enmascaramiento de Credenciales
- Credenciales enmascaradas en logs de Jenkins
- Uso obligatorio de variables de ambiente
- Plantillas de gestión de secretos

#### Plantilla de Secretos
```bash
# config/secrets.env.template
DB_PASSWORD_DEV=valor-dev
DB_PASSWORD_STAGING=valor-staging
DB_PASSWORD_PROD=valor-prod
NEXUS_PASSWORD=admin123
```

### 4. Soporte para Código Fuente en ZIP

Compilar aplicaciones desde archivos ZIP sin necesidad de Git:

```bash
./upload-source.sh mi-aplicacion.zip dev wildfly
```

El script automáticamente:
1. Extrae el código fuente
2. Escanea por contraseñas hardcodeadas
3. Compila con Maven
4. Ejecuta pruebas
5. Despliega a WildFly o JBoss

### 5. Repositorio Maven Local por Aplicación

Cada aplicación/ambiente tiene su propio repositorio Maven (.m2):
```
.m2/
├── repository-dev/      # Dependencias para desarrollo
├── repository-staging/  # Dependencias para staging
└── repository-prod/     # Dependencias para producción
```

Esto permite:
- Librerías específicas por ambiente
- Properties files versionados
- Aislamiento entre aplicaciones
- Control total de dependencias

### 6. Versionado Automático

Cada build genera una versión única:
```
Formato: {BUILD_NUMBER}-{TIMESTAMP}
Ejemplo: 42-20251025-143022
```

Información incluida en cada artefacto:
- Número de build
- Timestamp
- Commit de Git
- Branch de Git
- Ambiente objetivo
- Servidor objetivo

### 7. Control de Versiones de Properties

Las configuraciones se versionan junto con el código:

```bash
# Cada build genera
properties-prod-42-20251025-143022.tar.gz

# Conteniendo
- application.properties
- database.properties
- metadata.json (información de versión)
```

Almacenado en Nexus para:
- Auditoría completa
- Rollback a versiones anteriores
- Trazabilidad de cambios

### 8. Pipeline de CI/CD Mejorado

El pipeline incluye las siguientes etapas:

1. **Inicialización**: Configuración de versión y ambiente
2. **Lectura de Configuración**: Carga build-config.yml
3. **Carga de Properties**: Properties específicos del ambiente
4. **Checkout/Extracción**: Desde Git o ZIP
5. **Escaneo de Seguridad**: Detección de contraseñas
6. **Setup Maven**: Repositorio local por ambiente
7. **Build**: Compilación con Maven
8. **Tests**: Ejecución de pruebas unitarias
9. **Análisis SonarQube**: Calidad y seguridad de código
10. **Quality Gate**: Verificación de umbrales de calidad
11. **Versionado**: Asignación de versión única
12. **Deploy a Nexus**: Almacenamiento de artefactos
13. **Deploy a Servidor**: Despliegue a WildFly/JBoss
14. **Almacenar Properties**: Versionado de configuraciones
15. **Verificación**: Health check post-despliegue

### 9. Respaldo y Restauración

Sistema completo de backup:

```bash
# Crear respaldo
./backup-restore.sh backup

# Listar respaldos
./backup-restore.sh list

# Restaurar desde respaldo
./backup-restore.sh restore 20251025_143022
```

Incluye:
- Configuraciones de todos los ambientes
- Jobs y credenciales de Jenkins
- Configuración de Nexus
- Base de datos de SonarQube
- Configuraciones de WildFly/JBoss

## Inicio Rápido

### 1. Instalación

```bash
git clone <url-repositorio>
cd CICD
./setup.sh
```

El script automáticamente:
- Descarga todas las imágenes Docker
- Inicia todos los servicios
- Configura usuarios administradores
- Espera a que los servicios estén listos

### 2. Acceder a Servicios

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| Jenkins | http://localhost:8080 | admin / admin |
| SonarQube | http://localhost:9000 | admin / admin |
| Nexus | http://localhost:8081 | admin / [generado] |
| WildFly | http://localhost:8090 | admin / admin |
| JBoss | http://localhost:8070 | admin / admin |

### 3. Desplegar Aplicación de Ejemplo

```bash
cd examples/webapp-sample
mvn clean package
docker cp target/*.war wildfly:/opt/jboss/wildfly/standalone/deployments/
```

Acceder: http://localhost:8090/webapp-sample-1.0.0-SNAPSHOT/

## Casos de Uso

### Caso 1: Migración de JBoss a WildFly

1. **Evaluar aplicación actual** en JBoss
2. **Actualizar dependencias** a Jakarta EE
3. **Probar en WildFly** (ambiente dev)
4. **Ejecutar en paralelo** JBoss y WildFly (staging)
5. **Migrar tráfico gradualmente** a WildFly
6. **Monitorear y optimizar**

Ver [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) para detalles completos.

### Caso 2: Build desde ZIP

Para código legacy sin Git:

```bash
# Comprimir código fuente
zip -r mi-app.zip src/ pom.xml

# Subir y compilar
./upload-source.sh mi-app.zip staging wildfly
```

### Caso 3: Compilación con Repositorio M2 Local

Para aplicaciones con librerías específicas:

1. Colocar JARs en `config/environments/prod/.m2/repository/`
2. Crear `settings.xml` específico
3. Pipeline usa automáticamente el repositorio correcto

### Caso 4: Implementación Multi-Ambiente

```bash
# Desarrollo
Pipeline → ENVIRONMENT=dev → WildFly dev

# Staging
Pipeline → ENVIRONMENT=staging → WildFly staging

# Producción
Pipeline → ENVIRONMENT=prod → WildFly prod
```

Cada ambiente con:
- Properties específicos
- Credenciales únicas
- Configuraciones optimizadas

## Gestión de Properties y Componentes

### Estructura de Properties por Aplicación

```
config/environments/
├── dev/
│   ├── app1/
│   │   ├── application.properties
│   │   ├── database.properties
│   │   └── .m2/repository/  # Librerías específicas
│   └── app2/
│       └── application.properties
├── staging/
│   ├── app1/
│   └── app2/
└── prod/
    ├── app1/
    └── app2/
```

### Versionado de Properties

Cada deployment crea:
```
nexus/properties/
└── mi-app/
    ├── 1.0.0-42-20251025-143022/
    │   ├── properties-dev-42-20251025-143022.tar.gz
    │   ├── properties-staging-42-20251025-143022.tar.gz
    │   └── properties-prod-42-20251025-143022.tar.gz
    └── 1.0.0-43-20251025-150301/
        └── ...
```

### Rollback de Properties

```bash
# Descargar versión anterior
curl -O http://nexus:8081/repository/maven-snapshots/\
properties/mi-app/1.0.0-41/properties-prod-41.tar.gz

# Extraer y aplicar
tar xzf properties-prod-41.tar.gz
cp properties-41/* config/environments/prod/
```

## Revisión de Código y Tests

### Análisis Automático con SonarQube

Cada build ejecuta:
- **Análisis de código**: Bugs, code smells, duplicación
- **Seguridad**: Vulnerabilidades, hotspots de seguridad
- **Cobertura**: Porcentaje de código probado
- **Complejidad**: Complejidad ciclomática
- **Mantenibilidad**: Deuda técnica

### Quality Gates

Configurables en SonarQube:
- Cobertura mínima: 80%
- Bugs críticos: 0
- Vulnerabilidades: 0
- Code smells: < 10
- Duplicación: < 3%

El pipeline falla si no se cumplen los umbrales.

### Tests Maven

```bash
# Unit tests
mvn test

# Integration tests
mvn verify

# Con SonarQube
mvn clean verify sonar:sonar
```

Reportes en:
- Jenkins: `/job/mi-app/lastBuild/testReport/`
- SonarQube: http://localhost:9000/projects

## Documentación Completa

### Guías Disponibles

1. **[README.md](README.md)**: Visión general y setup
2. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)**: Referencia rápida de comandos
3. **[USER_GUIDE.md](USER_GUIDE.md)**: Guía completa de usuario
4. **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)**: Migración JBoss a WildFly
5. **[CONFIGURATION.md](CONFIGURATION.md)**: Configuración avanzada
6. **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**: Solución de problemas

### Ejemplos Incluidos

1. **examples/pom.xml**: Proyecto Maven simple
2. **examples/webapp-sample/**: Aplicación web completa Jakarta EE

## Comandos Útiles

### Gestión de Servicios

```bash
# Iniciar todo
./setup.sh

# Detener todo
docker compose down

# Ver logs
docker compose logs -f wildfly

# Reiniciar servicio
docker compose restart jenkins

# Verificar estado
docker ps
docker stats
```

### Despliegue

```bash
# Build y deploy manual
mvn clean package
docker cp target/*.war wildfly:/opt/jboss/wildfly/standalone/deployments/

# Desde ZIP
./upload-source.sh app.zip prod wildfly

# Verificar deployment
docker exec wildfly ls -la /opt/jboss/wildfly/standalone/deployments/
```

### Respaldo

```bash
# Crear
./backup-restore.sh backup

# Restaurar
./backup-restore.sh restore 20251025_143022

# Listar
./backup-restore.sh list
```

## Mejores Prácticas

### Seguridad
1. ✅ Nunca hacer commit de secretos
2. ✅ Usar variables de ambiente
3. ✅ Cambiar contraseñas por defecto en producción
4. ✅ Ejecutar escaneo de seguridad en cada build
5. ✅ Revisar logs de SonarQube regularmente

### Versionado
1. ✅ Versionar todo: código, properties, dependencias
2. ✅ Mantener changelog de cambios
3. ✅ Tag de Git para releases
4. ✅ Almacenar artifacts en Nexus

### Ambientes
1. ✅ Mantener paridad entre ambientes
2. ✅ Probar en staging antes de producción
3. ✅ Properties específicos por ambiente
4. ✅ Usar feature flags para nuevas funcionalidades

### Respaldos
1. ✅ Backup diario en desarrollo
2. ✅ Backup semanal en staging
3. ✅ Backup antes de cada deployment a producción
4. ✅ Probar restauración regularmente

## Soporte

Para ayuda:
1. Revisar documentación en este repositorio
2. Verificar logs: `docker compose logs -f`
3. Consultar ejemplos: `cd examples/webapp-sample`
4. Crear issue en GitHub

## Conclusión

Este entorno CI/CD proporciona una solución completa y automatizada para:

✅ **Automatización**: Build, test, deploy completamente automatizado  
✅ **Migración**: Soporte para migración JBoss a WildFly  
✅ **Seguridad**: Escaneo y enmascaramiento de credenciales  
✅ **Flexibilidad**: Git, ZIP, multi-ambiente  
✅ **Versionado**: Control total de versiones  
✅ **Respaldo**: Sistema completo de backup/restore  
✅ **Documentación**: Guías completas en español e inglés

¡Listo para migrar y automatizar tus aplicaciones Java! 🚀
