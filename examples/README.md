# Example Maven Project

This directory contains a sample Maven project to demonstrate the CI/CD pipeline.

## Contents

- `pom.xml` - Maven project configuration with Nexus deployment settings
- `settings.xml` - Maven settings file with Nexus server credentials
- `src/main/java/com/example/Calculator.java` - Sample Java class
- `src/test/java/com/example/CalculatorTest.java` - Unit tests

## Building the Project

### Prerequisites

Make sure the CI/CD environment is running:
```bash
cd ..
./setup.sh
```

### Local Build

```bash
cd examples
mvn clean install
```

### Run Tests

```bash
mvn test
```

### SonarQube Analysis

```bash
mvn sonar:sonar \
  -Dsonar.projectKey=sample-project \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=admin \
  -Dsonar.password=admin
```

### Deploy to Nexus

First, copy `settings.xml` to `~/.m2/settings.xml` or use it directly:

```bash
mvn deploy -s settings.xml
```

## Using with Jenkins

1. Create a new Pipeline job in Jenkins
2. Point it to this repository
3. Use the Jenkinsfile at the root of the repository
4. The pipeline will automatically:
   - Build the project
   - Run tests
   - Analyze with SonarQube
   - Deploy to Nexus

## Project Structure

```
examples/
├── pom.xml
├── settings.xml
├── src/
│   ├── main/
│   │   └── java/
│   │       └── com/
│   │           └── example/
│   │               └── Calculator.java
│   └── test/
│       └── java/
│           └── com/
│               └── example/
│                   └── CalculatorTest.java
└── README.md
```
