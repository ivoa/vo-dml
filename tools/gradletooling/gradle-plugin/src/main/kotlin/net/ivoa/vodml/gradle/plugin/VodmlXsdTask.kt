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
 * Task to generate XML schema files from vodsl.
 */
open class VodmlXsdTask  @Inject constructor(ao1: ArchiveOperations) : VodmlBaseTask(ao1)
{

    @get:OutputDirectory
    val schemaDir : DirectoryProperty = project.objects.directoryProperty()

    @Input
    @Optional
    val modelsToGenerate : Property<String> = project.objects.property(String::class.java)

    @TaskAction
    fun doXsdGenerate() {
        logger.info("Generating XML schema ")
        logger.debug("Looked in ${vodmlDir.get()}")
        val eh = ExternalModelHelper(project, ao, logger)
        val actualCatalog = eh.makeCatalog(vodmlFiles, catalogFile)
        val allBinding = bindingFiles.files.plus(eh.externalBinding())
        vodmlFiles.forEach {
            val shortname = it.nameWithoutExtension
            val outfile = schemaDir.file("$shortname.xsd")
            logger.debug("Generating XML schema from  ${it.name} to ${outfile.get().asFile.absolutePath}")
            Vodml2xsdNew.doTransform(it.absoluteFile, mapOf(
                "binding" to allBinding.joinToString(separator = ",") { it.toURI().toURL().toString() }
            ),
                actualCatalog, outfile.get().asFile)
        }
        logger.info("Generating JSON schema")
        vodmlFiles.forEach {
            val shortname = it.nameWithoutExtension
            val outfile = schemaDir.file("$shortname.json")
            logger.debug("Generating JSON schema from  ${it.name} to ${outfile.get().asFile.absolutePath}")
            Vodml2json.doTransform(it.absoluteFile, mapOf(
                "binding" to allBinding.joinToString(separator = ",") { it.toURI().toURL().toString() }
            ),
                actualCatalog, outfile.get().asFile)
        }

    }
}