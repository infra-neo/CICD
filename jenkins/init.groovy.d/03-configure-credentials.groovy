import jenkins.model.Jenkins
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import org.jenkinsci.plugins.plaincredentials.impl.*

def instance = Jenkins.getInstance()
def domain = Domain.global()
def store = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// SonarQube credentials
def sonarToken = new StringCredentialsImpl(
    CredentialsScope.GLOBAL,
    "sonarqube-token",
    "SonarQube Token",
    hudson.util.Secret.fromString("admin")
)

// Nexus credentials
def nexusCredentials = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "nexus-credentials",
    "Nexus Credentials",
    "admin",
    "admin123"
)

// Add credentials
if (!store.getCredentials(domain).find { it.id == "sonarqube-token" }) {
    store.addCredentials(domain, sonarToken)
    println "SonarQube token credential added"
}

if (!store.getCredentials(domain).find { it.id == "nexus-credentials" }) {
    store.addCredentials(domain, nexusCredentials)
    println "Nexus credentials added"
}

instance.save()
println "Credentials configured successfully"
