import jenkins.model.Jenkins
import hudson.plugins.sonar.SonarGlobalConfiguration
import hudson.plugins.sonar.SonarInstallation

def instance = Jenkins.getInstance()

// Configure SonarQube server
def sonarConfig = instance.getDescriptor(SonarGlobalConfiguration.class)

def sonarInstallation = new SonarInstallation(
    "SonarQube",
    "http://sonarqube:9000",
    "sonarqube-token",
    null,
    null,
    null,
    null,
    null
)

sonarConfig.setInstallations(sonarInstallation)
sonarConfig.save()

println "SonarQube server configured"
