package net.ivoa.vodml.gradle.plugin

import org.gradle.api.DefaultTask
import org.gradle.api.file.ArchiveOperations
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.*
import javax.inject.Inject


/*
 * Created on 13/09/2022 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */

/**
 * Task to generate XML schema files from vodsl
 */
open class VodmlXsdTask  @Inject constructor(private val ao: ArchiveOperations) : DefaultTask()
{
    @get:[InputDirectory PathSensitive(PathSensitivity.RELATIVE)]
    val vodmlDir: DirectoryProperty = project.objects.directoryProperty()

    @get:InputFiles
    val vodmlFiles: ConfigurableFileCollection = project.objects.fileCollection()

    @get:InputFile
    @Optional
    val catalogFile: RegularFileProperty = project.objects.fileProperty()

    @get:OutputDirectory
    val schemaDir : DirectoryProperty = project.objects.directoryProperty()

    @get:InputFiles
    val bindingFiles: ConfigurableFileCollection = project.objects.fileCollection()


    @Input
    @Optional
    val modelsToGenerate : Property<String> = project.objects.property(String::class.java)

    @TaskAction
    fun doXsdGenerate() {
        logger.info("Generating XML schema for VO-DML files ${vodmlFiles.files.joinToString { it.name }}")
        logger.info("Looked in ${vodmlDir.get()}")
        val eh = ExternalModelHelper(project, ao, logger)
        val actualCatalog = eh.makeCatalog(vodmlFiles, catalogFile)
        val allBinding = bindingFiles.files.plus(eh.externalBinding())
        vodmlFiles.forEach {
            val shortname = it.nameWithoutExtension
            val outfile = schemaDir.file("$shortname.xsd")
            logger.info("Generating XML schema from  ${it.name} to ${outfile.get().asFile.absolutePath}")
            Vodml2xsd.doTransform(it.absoluteFile, mapOf(
                "binding" to allBinding.joinToString(separator = ",") { it.absolutePath }
            ),
                actualCatalog, outfile.get().asFile)
        }
    }
}