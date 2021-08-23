package net.ivoa.vodml.gradle.plugin

import net.ivoa.vodml.gradle.plugin.internal.MIN_REQUIRED_GRADLE_VERSION
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.artifacts.Dependency
import org.gradle.api.plugins.JavaPlugin
import org.gradle.api.plugins.JavaPluginExtension
import org.gradle.api.tasks.SourceSet
import org.gradle.api.tasks.SourceSetContainer
import org.gradle.api.tasks.TaskProvider
import org.gradle.api.tasks.util.PatternSet
import org.gradle.jvm.toolchain.JavaLanguageVersion
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
        val vodmlJavaTask: TaskProvider<VodmlJavaTask> = project.tasks.register(VODML_JAVA_TASK_NANE,VodmlJavaTask::class.java) { task ->
            task.description = "Generate Java classes from VO-DML models"
            task.vodmlFiles.setFrom(if (extension.vodmlFiles.isEmpty)
                extension.vodmlDir.asFileTree.matching(PatternSet().include("**/*.vo-dml.xml"))
            else
                extension.vodmlFiles
            )
            task.javaGenDir.set(extension.outputJavaDir)
            task.vodmlDir.set(extension.vodmlDir)
            task.bindingFiles.setFrom(extension.bindingFiles)
            task.configFile.set(extension.catalogFile)

            //add the generated source directory to the list of sources to compile IMPL - this feels a bit hacky
            val sourceSets = project.properties["sourceSets"] as SourceSetContainer

            sourceSets.named(SourceSet.MAIN_SOURCE_SET_NAME) {
                it.java.srcDir(task.javaGenDir)
                it.resources.srcDir(task.javaGenDir)
            }

        }
        //force java 8 - TODO support java version > 8
        val toolchain = project.extensions.getByType(JavaPluginExtension::class.java).toolchain
        toolchain.languageVersion.set(JavaLanguageVersion.of(8))

        // force java compile to depend on this task
        project.tasks.named(JavaPlugin.COMPILE_JAVA_TASK_NAME) {
            it.dependsOn.add(vodmlJavaTask)
        }
        project.tasks.named(JavaPlugin.PROCESS_RESOURCES_TASK_NAME)
        {
            it.dependsOn.add(vodmlJavaTask)
        }
        //add the dependencies for JAXB and JPA - using the eclipse implementation
       listOf("javax.xml.bind:jaxb-api:2.3.1",
            "org.glassfish.jaxb:jaxb-runtime:2.3.4",
            "org.eclipse.persistence:org.eclipse.persistence.jpa:2.7.9",  // supports JPA 2.2
            "org.eclipse.persistence:org.eclipse.persistence.moxy:2.7.9" //alternative Jaxb runtime...
        ).forEach {
            project.dependencies.addProvider(
                JavaPlugin.IMPLEMENTATION_CONFIGURATION_NAME,
                project.objects.property(Dependency::class.java).convention(
                    project.dependencies.create(it)
                )
            )
        }
    }
}
