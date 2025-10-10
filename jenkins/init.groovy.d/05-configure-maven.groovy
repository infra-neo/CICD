import jenkins.model.Jenkins
import hudson.tasks.Maven
import hudson.tools.InstallSourceProperty
import hudson.tools.ToolProperty
import hudson.tools.ToolPropertyDescriptor
import hudson.util.DescribableList

def instance = Jenkins.getInstance()

// Configure Maven
def mavenDesc = instance.getDescriptor("hudson.tasks.Maven")

def mavenInstaller = new Maven.MavenInstaller("3.9.2")
def installSourceProperty = new InstallSourceProperty([mavenInstaller])

def maven = new Maven.MavenInstallation(
    "Maven 3.9.2",
    null,
    [installSourceProperty]
)

mavenDesc.setInstallations(maven)
mavenDesc.save()

println "Maven configured"
