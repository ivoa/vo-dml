package net.ivoa.vodml.gradle.plugin

import net.ivoa.vodml.gradle.plugin.internal.MIN_REQUIRED_GRADLE_VERSION
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.plugins.JavaPlugin
import org.gradle.api.tasks.util.PatternSet
import org.gradle.util.GradleVersion

/**
 * A plugin that defines all VO-DML tooling tasks.
 */
class VodmlGradlePlugin: Plugin<Project> {
    companion object {
        const val VODML_EXTENSION_NAME = "vodml"
        const val VODML_PLUGIN_ID = "net.ivoa.vodml-tools"
        const val VODML_CONFIG_NAME = "vodml"
        const val VODML_DOC_TASK_NANE = "vodmlDoc"
        const val VODML_VAL_TASK_NANE = "vodmlValidate"
        const val VODML_JAVA_TASK_NANE = "vodmlGenerateJava"
    }
    override fun apply(project: Project) {
        project.logger.info("Applying $VODML_PLUGIN_ID to project ${project.name}")
        check(GradleVersion.current() >= MIN_REQUIRED_GRADLE_VERSION) {
            "The $VODML_PLUGIN_ID plugin requires Gradle $MIN_REQUIRED_GRADLE_VERSION or higher."
        }
        project.plugins.apply(JavaPlugin::class.java) // add the java plugin as we are going to generate java eventually
        val extension = project.extensions.create(VODML_EXTENSION_NAME, VodmlExtension::class.java)

        // Register a task
        project.tasks.register("greeting") { task ->
            task.doLast {
                println("Hello from plugin 'vodml'")
            }
        }
        // register the doc task
        project.tasks.register(VODML_DOC_TASK_NANE,VodmlDocTask::class.java) {
            it.description = "create documentation for VO-DML models"
            it.vodmlFiles.setFrom(if (extension.vodmlFiles.isEmpty)
                extension.vodmlDir.asFileTree.matching(PatternSet().include("**/*.vo-dml.xml"))
            else
                extension.vodmlFiles
            )
            it.docDir.set(extension.outputDocDir)
            it.vodmlDir.set(extension.vodmlDir)
        }
        // register the validate task
        project.tasks.register(VODML_VAL_TASK_NANE,VodmlValidateTask::class.java) {
            it.description = "validate VO-DML models"
            it.vodmlFiles.setFrom(if (extension.vodmlFiles.isEmpty)
                extension.vodmlDir.asFileTree.matching(PatternSet().include("**/*.vo-dml.xml"))
            else
                extension.vodmlFiles
            )
            it.docDir.set(extension.outputDocDir)
            it.vodmlDir.set(extension.vodmlDir)
        }
        // register the Java generation task
        project.tasks.register(VODML_JAVA_TASK_NANE,VodmlJavaTask::class.java) {
            it.description = "generate Java classes from VO-DML models"
            it.vodmlFiles.setFrom(if (extension.vodmlFiles.isEmpty)
                extension.vodmlDir.asFileTree.matching(PatternSet().include("**/*.vo-dml.xml"))
            else
                extension.vodmlFiles
            )
            it.docDir.set(extension.outputDocDir)
            it.vodmlDir.set(extension.vodmlDir)
        }


    }
}
