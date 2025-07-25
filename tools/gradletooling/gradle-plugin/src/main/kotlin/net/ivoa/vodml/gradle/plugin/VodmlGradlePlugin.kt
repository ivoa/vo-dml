package net.ivoa.vodml.gradle.plugin

import net.ivoa.vodml.gradle.plugin.internal.MIN_REQUIRED_GRADLE_VERSION
import org.gradle.api.DefaultTask
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.artifacts.Dependency
import org.gradle.api.plugins.JavaLibraryPlugin
import org.gradle.api.plugins.JavaPlugin
import org.gradle.api.plugins.JavaPluginExtension
import org.gradle.api.tasks.SourceSet
import org.gradle.api.tasks.SourceSetContainer
import org.gradle.api.tasks.TaskProvider
import org.gradle.api.tasks.Copy
import org.gradle.api.tasks.util.PatternSet
import org.gradle.jvm.tasks.Jar
import org.gradle.jvm.toolchain.JavaLanguageVersion
import org.gradle.util.GradleVersion

/**
 * A plugin that defines all VO-DML tooling tasks.
 */
class VodmlGradlePlugin: Plugin<Project> {
    companion object {
        const val VODML_EXTENSION_NAME = "vodml"
        const val VODML_PLUGIN_ID = "net.ivoa.vo-dml.vodmltools"
        const val VODML_CONFIG_NAME = "vodml"
        const val VODML_DOC_TASK_NAME = "vodmlDoc"
        const val VODML_SITE_DOC_TASK_NAME = "vodmlSite"
        const val VODML_VAL_TASK_NAME = "vodmlValidate"
        const val VODML_JAVA_TASK_NAME_OLD = "vodmlGenerateJava"
        const val VODML_JAVA_TASK_NAME = "vodmlJavaGenerate"
        const val VODML_VODSL_TASK_NAME = "vodslToVodml"
        const val VODML_TO_VODSL_TASK_NAME = "vodmlToVodsl"
        const val VODML_TO_PYTHON_TASK_NAME = "vodmlPythonGenerate"
        const val VODML_SCHEMA_TASK_NAME = "vodmlSchema"
        const val XSD_TO_VODSL_TASK_NAME = "vodmlXsdToVodsl"
    }
    override fun apply(project: Project) {
        project.logger.info("Applying $VODML_PLUGIN_ID to project ${project.name}")
        check(GradleVersion.current() >= MIN_REQUIRED_GRADLE_VERSION) {
            "The $VODML_PLUGIN_ID plugin requires Gradle $MIN_REQUIRED_GRADLE_VERSION or higher."
        }
        project.plugins.apply(JavaLibraryPlugin::class.java) // add the java plugin as we are going to generate java eventually

        val extension = project.extensions.create(VODML_EXTENSION_NAME, VodmlExtension::class.java)

        // register the doc task
        project.tasks.register(VODML_DOC_TASK_NAME,VodmlDocTask::class.java) {
            it.description = "create documentation for VO-DML models"
            setVodmlFiles(it,extension,project)
            it.docDir.set(extension.outputDocDir)
            it.modelsToDocument.set(extension.modelsToDocument)
        }
        // register the site doc task
        project.tasks.register(VODML_SITE_DOC_TASK_NAME,VodmlSiteTask::class.java) {
            it.description = "create mkdocs site for VO-DML models"
            setVodmlFiles(it,extension,project)
            it.docDir.set(extension.outputSiteDir)
            it.modelsToDocument.set(extension.modelsToDocument)
        }
        // register the schema task
        val schematask: TaskProvider<VodmlSchemaTask> = project.tasks.register(VODML_SCHEMA_TASK_NAME,VodmlSchemaTask::class.java) { task->
            task.description = "create schema for VO-DML models"
            setVodmlFiles(task,extension,project)
            task.schemaDir.set(extension.outputSchemaDir)
            task.modelsToGenerate.set(extension.modelsToDocument)
            val sourceSets = project.properties["sourceSets"] as SourceSetContainer

            //IMPL this seems hacky as the tests should just pick up the normal resources above, but they do not seem to
            sourceSets.named(SourceSet.TEST_SOURCE_SET_NAME){
                it.resources.srcDir(task.schemaDir)
            }

        }
        // register the validate task
        project.tasks.register(VODML_VAL_TASK_NAME,VodmlValidateTask::class.java) { task ->
            task.description = "validate VO-DML models"
            setVodmlFiles(task,extension,project)
            task.docDir.set(extension.outputDocDir)
            task.outputs.upToDateWhen { false } //IMPL because this is mainly an info task at the moment -i.e. results shown on stdout
        }


        project.tasks.register(VODML_VODSL_TASK_NAME, VodslTask::class.java) { task ->
            task.description = "convert VODSL to VO-DML"
            task.vodslFiles.setFrom(if (extension.vodslFiles.isEmpty)
                extension.vodslDir.asFileTree.matching(PatternSet().include("**/*.vodsl"))
            else
                extension.vodslFiles
            )
            task.vodmlDir.set(extension.vodmlDir)
        }

        project.tasks.register(VODML_TO_VODSL_TASK_NAME, VodmlToVodslTask::class.java) { task ->
            task.description = "convert VO-DML to VODSL on the commandline"
        }
        project.tasks.register(XSD_TO_VODSL_TASK_NAME, XsdToVodslTask::class.java) { task ->
            task.description = "convert XML schema to VODSL on the commandline"
        }

        // register the Java generation task
        val vodmlJavaTask: TaskProvider<VodmlJavaTask> = project.tasks.register(VODML_JAVA_TASK_NAME,VodmlJavaTask::class.java) { task ->
            task.description = "Generate Java classes from VO-DML models"
            setVodmlFiles(task,extension,project)
            task.javaGenDir.set(extension.outputJavaDir)

            //add the generated source directory to the list of sources to compile
            // IMPL - recommendation of https://docs.gradle.org/current/dsl/org.gradle.api.tasks.SourceSetOutput.html#org.gradle.api.tasks.SourceSetOutput does not seem to work
            //
            val sourceSets = project.properties["sourceSets"] as SourceSetContainer

            sourceSets.named(SourceSet.MAIN_SOURCE_SET_NAME) {
                it.java.srcDir(task.javaGenDir)
                it.resources.srcDir(task.javaGenDir)

            }

            // add the vo-dml and binding files to the jar setup
            val jartask = project.tasks.named(JavaPlugin.JAR_TASK_NAME).get() as Jar
            jartask.from(task.vodmlFiles)
            jartask.from(task.bindingFiles)
            jartask.manifest {
                it.attributes(mapOf(
                    "VODML-source" to task.vodmlFiles.files.joinToString{file -> file.name},
                    "VODML-binding" to task.bindingFiles.files.joinToString { file -> file.name }
                ))
            }




        }
        //IMPL this is part of the hack to try to get the generated schema on the classpath - have been copied all over the place!!
        // some of the behaviour might be because the default place to generate the schema is into the build directory??
        val processResources = project.tasks.named(JavaPlugin.PROCESS_RESOURCES_TASK_NAME).get() as Copy
        processResources.from(schematask)
        processResources.dependsOn.add(schematask)

        //using java 17 minimum
        val toolchain = project.extensions.getByType(JavaPluginExtension::class.java).toolchain
        toolchain.languageVersion.set(JavaLanguageVersion.of(17))

        // force java compile to depend on this task
        project.tasks.named(JavaPlugin.COMPILE_JAVA_TASK_NAME) {
            it.dependsOn.add(vodmlJavaTask)
            it.dependsOn.add(schematask)
        }



        //register a task with the old task name as an alias
        project.tasks.register(VODML_JAVA_TASK_NAME_OLD,DefaultTask::class.java) {
            it.description = "deprecated task name for generating Java from VO-DML models"
            it.dependsOn.add(vodmlJavaTask)
        }

//python task
        project.tasks.register(VODML_TO_PYTHON_TASK_NAME,VodmlPythonTask::class.java) { task ->
            task.description = "generate python classes from VO-DML models"
            setVodmlFiles(task,extension,project)
            task.pythonGenDir.set(extension.outputPythonDir)
        }



        //add the dependencies for JAXB and JPA - using the hibernate implementation
       listOf("org.javastro.ivoa.vo-dml:vodml-runtime:0.8.8",
            "jakarta.xml.bind:jakarta.xml.bind-api:4.0.0",
            "org.glassfish.jaxb:jaxb-runtime:4.0.5",
//             "org.eclipse.persistence:org.eclipse.persistence.jpa:2.7.10",  // supports JPA 2.2
//            "org.eclipse.persistence:org.eclipse.persistence.moxy:3.0.2", //alternative Jaxb runtime...
             "org.hibernate.orm:hibernate-core:6.6.22.Final"
//             ,"jakarta.persistence:jakarta.persistence-api:3.0.0" // dont use until go to hibernate 6
             ,"com.fasterxml.jackson.core:jackson-databind:2.15.1"
             ,"org.eclipse.microprofile.openapi:microprofile-openapi-api:2.0.1"

       ).forEach {
            project.dependencies.addProvider(
                JavaPlugin.API_CONFIGURATION_NAME, // want them exported
                project.objects.property(Dependency::class.java).convention(
                    project.dependencies.create(it)
                )
            )
        }

        listOf(
            "org.eclipse.microprofile.openapi:microprofile-openapi-api:2.0.1"

        ).forEach {
            project.dependencies.addProvider(
                JavaPlugin.IMPLEMENTATION_CONFIGURATION_NAME, // don't want exported
                project.objects.property(Dependency::class.java).convention(
                    project.dependencies.create(it)

                )
            )
        }
    }

    private fun setVodmlFiles(
        task: VodmlBaseTask,
        extension: VodmlExtension,
        project: Project
    ) {
        task.vodmlFiles.setFrom(
            if (extension.vodmlFiles.isEmpty)
                extension.vodmlDir.asFileTree.matching(PatternSet().include("**/*.vo-dml.xml"))
            else
                extension.vodmlFiles
        )
        task.vodmlDir.set(extension.vodmlDir)
        task.vocabularyDir.set(if (extension.vocabularyDir.isPresent)
            extension.vocabularyDir
            else
            extension.vodmlDir

        )

        task.catalogFile.set(extension.catalogFile)
        task.bindingFiles.setFrom(if (extension.bindingFiles.isEmpty)
            project.projectDir.listFiles{f -> f.name.endsWith("vodml-binding.xml")}
        else
            extension.bindingFiles
        )

    }


}
