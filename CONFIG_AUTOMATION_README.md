# Configuración Automatizada desde Excel a GitLab CI/CD

Este proyecto implementa un sistema automatizado para leer configuración desde un archivo Excel y configurarla directamente en GitLab CI/CD.

## 📋 Descripción

El sistema permite gestionar todas las configuraciones de despliegue (IPs, puertos, rutas, versiones de librerías, credenciales de Nexus, properties) en un archivo Excel centralizado (`Project_Master_Config.xlsx`) y sincronizarlas automáticamente con GitLab CI/CD.

## 🏗️ Arquitectura

### Componentes Principales

1. **config_loader.py**: Script Python que:
   - Lee el archivo Excel usando pandas
   - Autentica con GitLab usando la API
   - Crea/actualiza variables de CI/CD con scoping por ambiente
   - Genera archivos de configuración desde templates Jinja2

2. **.gitlab-ci.yml**: Pipeline de GitLab CI con:
   - Job `configure-project` para ejecutar la configuración
   - Job `validate-excel` para validar la estructura del Excel
   - Gestión de artefactos para archivos generados

3. **templates/**: Directorio con plantillas Jinja2 para generar archivos de configuración

4. **Project_Master_Config.xlsx**: Archivo Excel con la configuración maestra

## 📊 Estructura del Excel

### Hoja 'Variables'

Columnas requeridas:
- **Key**: Nombre de la variable
- **Value**: Valor de la variable
- **Environment**: Ambiente (QA, PRE, PROD, ALL)
- **Protected**: Si la variable es protegida (True/False)

Ejemplo:
```
Key             | Value                  | Environment | Protected
----------------|------------------------|-------------|----------
JAVA_VERSION    | 11                     | ALL         | False
NEXUS_URL       | https://nexus.com      | ALL         | False
NEXUS_PASSWORD  | secret123              | ALL         | True
JAVA_OPTS       | -Xms512m -Xmx1024m     | QA          | False
JAVA_OPTS       | -Xms2048m -Xmx4096m    | PROD        | False
```

### Hoja 'Build_Info'

Columnas requeridas:
- **Component**: Nombre del componente
- **Version**: Versión del componente
- **Maven_Profile**: Perfil de Maven asociado

Ejemplo:
```
Component      | Version        | Maven_Profile
---------------|----------------|---------------
spring-boot    | 2.7.5          | spring
hibernate      | 5.6.12.Final   | persistence
```

## 🚀 Uso

### Configuración Inicial

1. **Configurar Variables de GitLab**:
   
   En GitLab, ve a: `Settings -> CI/CD -> Variables` y añade:
   
   - `GIT_TOKEN`: Token de acceso personal de GitLab con permisos `api`
   - `CI_PROJECT_ID`: Se configura automáticamente por GitLab

2. **Preparar el Excel**:
   
   Edita `Project_Master_Config.xlsx` con tus configuraciones siguiendo la estructura descrita arriba.

3. **Crear Templates (Opcional)**:
   
   Crea archivos `.j2` en el directorio `templates/` para generar archivos de configuración personalizados.

### Ejecución

#### Ejecución Manual

1. Ve a `CI/CD -> Pipelines` en GitLab
2. Click en "Run Pipeline"
3. Selecciona la rama deseada
4. El job `configure-project` se ejecutará y configurará las variables

#### Ejecución Automática

El pipeline se ejecuta automáticamente cuando:
- Se modifica el archivo `Project_Master_Config.xlsx`
- Se modifican los scripts de configuración
- Se modifican las plantillas

### Verificar Resultados

1. **Variables CI/CD**: Ve a `Settings -> CI/CD -> Variables` para ver las variables configuradas
2. **Archivos Generados**: Descarga los artefactos del job para ver los archivos de configuración generados
3. **Logs**: Revisa los logs del job para ver detalles de la ejecución

## 📁 Estructura de Archivos

```
CICD/
├── .gitlab-ci.yml                    # Pipeline de GitLab CI
├── config_loader.py                  # Script principal de configuración
├── Project_Master_Config.xlsx        # Archivo Excel con configuración
├── templates/                        # Plantillas Jinja2
│   ├── application.properties.j2    # Template para properties
│   └── pom.xml.j2                   # Template para Maven POM
└── generated_configs/               # Archivos generados (ignorado en git)
```

## 🔧 Variables de Entorno

El script utiliza las siguientes variables de entorno:

- `GIT_TOKEN` (requerido): Token de acceso de GitLab
- `CI_PROJECT_ID` (requerido): ID del proyecto (auto-configurado en CI)
- `CI_SERVER_URL` (opcional): URL de GitLab (default: https://gitlab.com)
- `EXCEL_PATH` (opcional): Ruta al archivo Excel (default: Project_Master_Config.xlsx)

## 🎯 Características

### Environment Scoping

Las variables se asignan al ambiente correcto:
- `ALL` o `*`: Variable global (todos los ambientes)
- `QA`: Solo ambiente QA
- `PRE`: Solo ambiente PRE
- `PROD`: Solo ambiente PROD

### Manejo de Variables Existentes

- Si una variable ya existe, se actualiza su valor
- Si una variable no existe, se crea nueva
- Se maneja el scoping por ambiente correctamente

### Generación de Archivos

El sistema puede generar archivos de configuración usando templates Jinja2:
- Los templates tienen acceso a todas las variables del Excel
- Los archivos generados se guardan como artefactos en GitLab
- Los templates pueden acceder a variables por ambiente

### Validación

El job `validate-excel` valida:
- Que el archivo Excel exista
- Que las hojas requeridas estén presentes
- Que las columnas requeridas estén presentes
- Se ejecuta automáticamente en merge requests

## 🛡️ Seguridad

- Las variables protegidas solo son accesibles en ramas protegidas
- El token de GitLab debe tener solo los permisos necesarios (`api`)
- Las credenciales sensibles deben marcarse como `Protected: True`
- El pipeline solo se ejecuta en ramas autorizadas

## 📝 Ejemplos de Templates

### application.properties.j2

```jinja2
# Application Properties
{% if 'ALL' in variables %}
{% for key, value in variables['ALL'].items() %}
{{ key }}={{ value }}
{% endfor %}
{% endif %}
```

### pom.xml.j2

```jinja2
<properties>
{% if build_info %}
{% for component, info in build_info.items() %}
    <{{ component }}.version>{{ info.version }}</{{ component }}.version>
{% endfor %}
{% endif %}
</properties>
```

## 🔍 Solución de Problemas

### Error: GIT_TOKEN no configurado

Asegúrate de configurar la variable `GIT_TOKEN` en `Settings -> CI/CD -> Variables`.

### Error: Excel no encontrado

Verifica que el archivo `Project_Master_Config.xlsx` esté en la raíz del repositorio.

### Error: Columnas faltantes

Revisa que el Excel tenga todas las columnas requeridas en cada hoja.

### Variables no se actualizan

Verifica que el token tenga permisos `api` y que el proyecto ID sea correcto.

## 📚 Referencias

- [GitLab CI/CD Variables](https://docs.gitlab.com/ee/ci/variables/)
- [Python GitLab API](https://python-gitlab.readthedocs.io/)
- [Jinja2 Templates](https://jinja.palletsprojects.com/)
- [Pandas Documentation](https://pandas.pydata.org/docs/)

## 🤝 Contribuciones

Para contribuir al proyecto:

1. Crea una rama desde `develop`
2. Realiza tus cambios
3. Ejecuta el pipeline para validar
4. Crea un merge request

## 📄 Licencia

Este proyecto es parte del sistema CI/CD interno.
