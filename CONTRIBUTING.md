# Contributing Guide

Thank you for your interest in contributing to this CI/CD environment!

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. Check if the issue already exists in the issue tracker
2. If not, create a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Your environment details (OS, Docker version, etc.)
   - Relevant logs or error messages

### Suggesting Enhancements

Have an idea to improve the CI/CD environment? Great!

1. Open an issue describing your enhancement
2. Explain the use case and benefits
3. If possible, provide implementation suggestions

### Pull Requests

We welcome pull requests! Here's how to contribute code:

#### Setup Development Environment

```bash
# Fork the repository
git clone https://github.com/YOUR-USERNAME/CICD.git
cd CICD

# Create a feature branch
git checkout -b feature/your-feature-name

# Start the environment
./setup.sh
```

#### Making Changes

1. **Follow existing patterns**: Look at how things are currently done
2. **Test your changes**: Use `./validate.sh` to ensure everything works
3. **Update documentation**: Update relevant .md files
4. **Keep it simple**: Avoid unnecessary complexity

#### Testing Your Changes

Before submitting:

```bash
# Validate configuration
docker compose config

# Test setup
docker compose down -v
./setup.sh

# Run validation
./validate.sh

# Test manually
# - Access all services
# - Run example pipeline
# - Check logs for errors
```

#### Commit Guidelines

Use clear, descriptive commit messages:

```bash
# Good
git commit -m "Add PostgreSQL health check to docker-compose"
git commit -m "Fix Jenkins plugin installation timeout"
git commit -m "Update README with troubleshooting steps"

# Bad
git commit -m "fix bug"
git commit -m "updates"
git commit -m "changes"
```

#### Submitting Pull Request

1. Push your branch to your fork
2. Create a pull request with:
   - Clear title describing the change
   - Detailed description of what and why
   - Reference to related issues (if any)
   - Testing steps you performed

## Development Guidelines

### Adding New Services

To add a new service to the stack:

1. **Update docker-compose.yml**:
```yaml
services:
  your-service:
    image: your-image:tag
    container_name: your-service
    restart: unless-stopped
    ports:
      - "port:port"
    volumes:
      - your_service_data:/data
    networks:
      - cicd-network

volumes:
  your_service_data:
```

2. **Update setup.sh** to wait for the new service
3. **Update validate.sh** to check the service health
4. **Update README.md** with service documentation
5. **Add to TROUBLESHOOTING.md** with common issues

### Adding Jenkins Plugins

To add new Jenkins plugins:

1. Edit `jenkins/init.groovy.d/02-install-plugins.groovy`
2. Add plugin name to the list:
```groovy
def plugins = [
    "git",
    "workflow-aggregator",
    "your-new-plugin",  // Add here
]
```

### Adding Jenkins Configuration

Create a new Groovy script in `jenkins/init.groovy.d/`:

1. Name it with a number prefix: `06-your-config.groovy`
2. Follow this template:
```groovy
import jenkins.model.Jenkins

def instance = Jenkins.getInstance()

// Your configuration code here

instance.save()
println "Your configuration completed"
```

### Modifying Jenkinsfile

When updating the default Jenkinsfile:

1. Keep it generic and reusable
2. Add comments for complex logic
3. Use environment variables for configuration
4. Test with the example project

### Documentation Standards

When updating documentation:

1. **Be clear and concise**: Use simple language
2. **Provide examples**: Show, don't just tell
3. **Update all relevant files**: README, QUICKSTART, etc.
4. **Test instructions**: Verify they actually work

#### File Purposes:

- `README.md`: Main documentation, comprehensive overview
- `QUICKSTART.md`: Fast setup guide, minimal explanation
- `CONFIGURATION.md`: Advanced configuration options
- `TROUBLESHOOTING.md`: Common problems and solutions
- `CONTRIBUTING.md`: This file, contribution guidelines

### Code Style

#### Shell Scripts

```bash
#!/bin/bash
set -e  # Exit on error

# Use meaningful variable names
SERVICE_NAME="jenkins"

# Add comments for complex logic
# This checks if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed"
    exit 1
fi

# Use functions for reusable code
check_service() {
    local service=$1
    docker ps | grep -q "$service"
}
```

#### Groovy Scripts

```groovy
import jenkins.model.Jenkins

// Clear comments
def instance = Jenkins.getInstance()

// Meaningful variable names
def pluginManager = instance.getPluginManager()

// Error handling
try {
    // Your code
} catch (Exception e) {
    println "Error: ${e.message}"
}

println "Configuration completed successfully"
```

#### YAML Files

```yaml
# Comments for complex configurations
services:
  service-name:
    image: image:tag
    # Indentation: 2 spaces
    environment:
      # Use meaningful names
      - SERVICE_CONFIG=value
```

### Testing Guidelines

#### Manual Testing Checklist

Before submitting a PR, verify:

- [ ] All services start successfully
- [ ] All services are accessible
- [ ] Example project builds
- [ ] Pipeline runs successfully
- [ ] All documentation is updated
- [ ] No errors in logs
- [ ] `./validate.sh` passes

#### Test on Clean Environment

```bash
# Complete reset
docker compose down -v
rm -rf jenkins/ examples/target/

# Fresh setup
./setup.sh

# Validate
./validate.sh
```

## Project Structure

```
CICD/
├── docker-compose.yml              # Main compose file
├── setup.sh                        # Setup automation
├── validate.sh                     # Validation tests
├── build-config.yml                # Build configuration
├── Jenkinsfile                     # Pipeline definition
├── README.md                       # Main documentation
├── QUICKSTART.md                   # Quick start guide
├── CONFIGURATION.md                # Advanced config
├── TROUBLESHOOTING.md              # Problem solving
├── CONTRIBUTING.md                 # This file
├── .gitignore                      # Git exclusions
├── docker-compose.override.yml.example  # Override template
├── jenkins/
│   └── init.groovy.d/             # Jenkins auto-config
│       ├── 01-admin-user.groovy
│       ├── 02-install-plugins.groovy
│       ├── 03-configure-credentials.groovy
│       ├── 04-configure-sonarqube.groovy
│       └── 05-configure-maven.groovy
└── examples/                       # Example project
    ├── pom.xml
    ├── settings.xml
    ├── README.md
    └── src/
```

## Common Contribution Areas

### Easy Contributions (Good First Issues)

- Fix typos in documentation
- Improve error messages
- Add more validation tests
- Enhance examples
- Add FAQ entries

### Medium Contributions

- Add new Jenkins plugins
- Improve Groovy init scripts
- Add health checks
- Create backup/restore scripts
- Add monitoring integration

### Advanced Contributions

- Add new services (e.g., GitLab, Harbor)
- Implement HTTPS/TLS
- Add clustering support
- Create Kubernetes manifests
- Implement advanced security features

## Release Process

1. Version is tracked in git tags
2. Changes are documented in release notes
3. Major versions may include breaking changes
4. Minor versions add features
5. Patches fix bugs

## Getting Help

Need help with your contribution?

- **Questions**: Open an issue with the "question" label
- **Discussions**: Use GitHub Discussions (if enabled)
- **Review**: Request review from maintainers

## Code Review Process

When you submit a PR:

1. Automated checks run (if configured)
2. Maintainers review the code
3. Feedback is provided
4. You make requested changes
5. PR is merged once approved

## Recognition

Contributors are recognized in:
- Git commit history
- Release notes
- Project README (for significant contributions)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

## Questions?

If you have questions about contributing, feel free to:
- Open an issue
- Check existing documentation
- Review closed issues and PRs for examples

Thank you for contributing to make this CI/CD environment better! 🚀
