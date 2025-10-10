import jenkins.model.Jenkins
import hudson.model.UpdateSite
import hudson.PluginWrapper

def instance = Jenkins.getInstance()
def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()

// List of plugins to install
def plugins = [
    "git",
    "workflow-aggregator",
    "pipeline-maven",
    "maven-plugin",
    "sonar",
    "nexus-artifact-uploader",
    "credentials",
    "credentials-binding",
    "config-file-provider",
    "docker-workflow",
    "pipeline-utility-steps"
]

println "Installing plugins..."

plugins.each { pluginName ->
    if (!pm.getPlugin(pluginName)) {
        println "Installing plugin: ${pluginName}"
        def plugin = uc.getPlugin(pluginName)
        if (plugin) {
            plugin.deploy(true)
        }
    } else {
        println "Plugin already installed: ${pluginName}"
    }
}

println "Plugins installation initiated. Jenkins will restart if needed."
