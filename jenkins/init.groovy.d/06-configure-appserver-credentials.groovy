import jenkins.model.Jenkins
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*

def instance = Jenkins.getInstance()
def domain = Domain.global()
def store = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// WildFly credentials
def wildflyCredentials = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "wildfly-credentials",
    "WildFly Server Credentials",
    "admin",
    "admin"
)

// JBoss credentials
def jbossCredentials = new UsernamePasswordCredentialsImpl(
    CredentialsScope.GLOBAL,
    "jboss-credentials",
    "JBoss Server Credentials",
    "admin",
    "admin"
)

// Add WildFly credentials
if (!store.getCredentials(domain).find { it.id == "wildfly-credentials" }) {
    store.addCredentials(domain, wildflyCredentials)
    println "WildFly credentials added"
}

// Add JBoss credentials
if (!store.getCredentials(domain).find { it.id == "jboss-credentials" }) {
    store.addCredentials(domain, jbossCredentials)
    println "JBoss credentials added"
}

instance.save()
println "Application server credentials configured successfully"
