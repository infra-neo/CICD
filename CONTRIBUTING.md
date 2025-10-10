# Guía de Contribución

¡Gracias por tu interés en contribuir al proyecto CI/CD Stack! Esta guía te ayudará a comenzar.

## 📋 Tabla de Contenidos

- [Código de Conducta](#código-de-conducta)
- [Cómo Contribuir](#cómo-contribuir)
- [Desarrollo Local](#desarrollo-local)
- [Reportar Bugs](#reportar-bugs)
- [Sugerir Mejoras](#sugerir-mejoras)
- [Pull Requests](#pull-requests)
- [Estilo de Código](#estilo-de-código)

## 🤝 Código de Conducta

Este proyecto se adhiere a un código de conducta. Al participar, se espera que mantengas un ambiente respetuoso y constructivo.

## 🚀 Cómo Contribuir

Hay muchas formas de contribuir:

1. **Reportar bugs** o problemas
2. **Sugerir nuevas características**
3. **Mejorar documentación**
4. **Enviar pull requests** con correcciones o nuevas features
5. **Revisar código** de otros contribuidores

## 💻 Desarrollo Local

### Prerrequisitos

- Git
- Docker y Docker Compose
- Maven (opcional, para desarrollo Java)
- Editor de texto o IDE

### Configurar el Entorno

1. **Fork el repositorio**
   ```bash
   # En GitHub, haz clic en "Fork"
   ```

2. **Clonar tu fork**
   ```bash
   git clone https://github.com/TU_USUARIO/CICD.git
   cd CICD
   ```

3. **Agregar upstream**
   ```bash
   git remote add upstream https://github.com/infra-neo/CICD.git
   ```

4. **Crear una rama para tu feature**
   ```bash
   git checkout -b feature/mi-nueva-caracteristica
   ```

5. **Iniciar el stack**
   ```bash
   sudo ./start.sh
   ```

### Hacer Cambios

1. **Realiza tus cambios**
   - Edita los archivos necesarios
   - Sigue las convenciones del proyecto

2. **Probar localmente**
   ```bash
   # Si modificaste la aplicación Java
   cd example-app
   mvn clean test
   
   # Si modificaste docker-compose.yml
   docker compose config --quiet
   
   # Verificar el stack
   ./health-check.sh
   ```

3. **Commit tus cambios**
   ```bash
   git add .
   git commit -m "feat: descripción breve de tu cambio"
   ```

4. **Push a tu fork**
   ```bash
   git push origin feature/mi-nueva-caracteristica
   ```

## 🐛 Reportar Bugs

Cuando reportes un bug, incluye:

### Template de Bug Report

```markdown
**Descripción del bug**
Una descripción clara y concisa del bug.

**Para Reproducir**
Pasos para reproducir el comportamiento:
1. Ve a '...'
2. Haz clic en '....'
3. Ejecuta '....'
4. Ver error

**Comportamiento esperado**
Descripción clara de lo que esperabas que sucediera.

**Capturas de pantalla**
Si aplica, agrega capturas de pantalla.

**Entorno:**
 - OS: [ej. Ubuntu 22.04]
 - Docker version: [ej. 24.0.0]
 - Docker Compose version: [ej. 2.20.0]

**Logs**
```
Pega aquí los logs relevantes
```

**Contexto adicional**
Cualquier otra información sobre el problema.
```

## 💡 Sugerir Mejoras

Para sugerir mejoras, abre un issue con:

### Template de Feature Request

```markdown
**¿Tu solicitud está relacionada con un problema?**
Descripción clara del problema. Ej: "Siempre me frustra cuando [...]"

**Describe la solución que te gustaría**
Descripción clara de lo que quieres que suceda.

**Describe alternativas que hayas considerado**
Descripción de soluciones alternativas que hayas considerado.

**Contexto adicional**
Cualquier otro contexto o capturas de pantalla sobre la solicitud.
```

## 🔄 Pull Requests

### Proceso

1. **Asegúrate de que tu código funciona**
   - Todos los tests pasan
   - El stack inicia correctamente
   - No hay errores de sintaxis

2. **Actualiza la documentación**
   - Si agregas una feature, actualiza README.md
   - Si cambias configuración, actualiza SETUP-GUIDE.md
   - Agrega comentarios en el código si es necesario

3. **Sigue las convenciones de commits**
   ```
   feat: Nueva característica
   fix: Corrección de bug
   docs: Cambios en documentación
   style: Cambios de formato (sin cambio de código)
   refactor: Refactorización
   test: Agregar o modificar tests
   chore: Cambios en build o herramientas
   ```

4. **Crea el Pull Request**
   - Ve a tu fork en GitHub
   - Haz clic en "New Pull Request"
   - Selecciona tu rama
   - Completa la descripción del PR

### Template de Pull Request

```markdown
**Descripción**
Descripción clara de los cambios realizados.

**Tipo de cambio**
- [ ] Bug fix
- [ ] Nueva feature
- [ ] Breaking change
- [ ] Actualización de documentación

**¿Cómo se ha probado?**
Descripción de las pruebas realizadas.

**Checklist**
- [ ] Mi código sigue el estilo del proyecto
- [ ] He realizado un auto-review de mi código
- [ ] He comentado código complejo
- [ ] He actualizado la documentación
- [ ] Mis cambios no generan nuevas advertencias
- [ ] He agregado tests que prueban mi fix/feature
- [ ] Tests nuevos y existentes pasan localmente
- [ ] El stack inicia correctamente

**Capturas de pantalla** (si aplica)
```

## 📝 Estilo de Código

### Docker Compose

```yaml
# Usar 2 espacios para indentación
services:
  service-name:
    image: imagen:tag
    container_name: prefijo-nombre
    environment:
      VARIABLE: valor
```

### Jenkinsfile

```groovy
// Usar 4 espacios para indentación
pipeline {
    agent any
    
    stages {
        stage('Nombre') {
            steps {
                echo 'Mensaje'
            }
        }
    }
}
```

### Java

```java
// Seguir convenciones de Java
public class MiClase {
    /**
     * Documentación JavaDoc
     */
    public void miMetodo() {
        // Código
    }
}
```

### Shell Scripts

```bash
#!/bin/bash
# Descripción del script

# Usar nombres descriptivos
function mi_funcion() {
    echo "Mensaje"
}
```

### Markdown

```markdown
# Título Principal

## Sección

- Lista con guiones
- Otro item

```bash
# Bloques de código con lenguaje especificado
comando
```
```

## 🧪 Testing

### Probar Cambios en Docker Compose

```bash
# Validar sintaxis
docker compose config --quiet

# Recrear servicios
docker compose up -d --force-recreate
```

### Probar Cambios en Java

```bash
cd example-app

# Compilar
mvn clean compile

# Ejecutar tests
mvn test

# Verificar con SonarQube (requiere token)
mvn sonar:sonar -Dsonar.login=TU_TOKEN
```

### Probar Cambios en Jenkinsfile

1. Iniciar el stack
2. Crear un pipeline en Jenkins
3. Ejecutar el pipeline
4. Verificar que todas las etapas pasan

## 📚 Recursos Adicionales

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Maven Guide](https://maven.apache.org/guides/)
- [Markdown Guide](https://www.markdownguide.org/)

## ❓ Preguntas

Si tienes preguntas:

1. Revisa la [documentación](README.md)
2. Busca en [issues existentes](https://github.com/infra-neo/CICD/issues)
3. Abre un [nuevo issue](https://github.com/infra-neo/CICD/issues/new)

## 🙏 Agradecimientos

Gracias por contribuir al proyecto! Tu ayuda hace que este proyecto sea mejor para todos.

## 📜 Proceso de Review

1. Un maintainer revisará tu PR
2. Pueden solicitar cambios
3. Una vez aprobado, se hará merge
4. Tu contribución será parte del proyecto!

## 🏆 Reconocimientos

Los contribuidores serán reconocidos en:
- README.md (sección de contribuidores)
- Release notes
- Git history

---

**¡Happy coding!** 🚀
