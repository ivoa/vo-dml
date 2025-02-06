package net.ivoa.vodml.gradle.plugin

import org.gradle.api.file.ArchiveOperations
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.*
import java.io.File
import javax.inject.Inject
import com.fasterxml.jackson.databind.ObjectMapper
import java.nio.file.Paths


/*
 * Created on 13/09/2022 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */

/**
 * Task to generate XML schema files from vodsl.
 */
open class VodmlSchemaTask  @Inject constructor(ao1: ArchiveOperations) : VodmlBaseTask(ao1)
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
            val s = Vodml2json.doTransformToString(it.absoluteFile, mapOf(
                "binding" to allBinding.joinToString(separator = ",") { it.toURI().toURL().toString() }
            ),
                actualCatalog)
            //prettyprint the generated JSON - i.e. going via jackson
            val mapper = ObjectMapper()
            val pretty = mapper.writerWithDefaultPrettyPrinter().writeValueAsString(mapper.readTree(s));
            outfile.get().asFile.writeText(pretty)
        }

        val xmlcat = java.nio.file.Paths.get(schemaDir.file("xmlcat.xml").get().asFile.toURI()).toUri().toString()
        val jsoncat = java.nio.file.Paths.get(schemaDir.file("jsoncat.txt").get().asFile.toURI()).toUri().toString()
        logger.info("generating Catalogues")
        logger.info("xml = $xmlcat")
        logger.info("json= $jsoncat")
        Vodml2Catalogues.doTransform(mapOf(
            "binding" to bindingFiles.joinToString(separator = ",") { it.toURI().toURL().toString() },
            "xml-catalogue" to xmlcat,
            "json-catalogue" to jsoncat

        )
            )

        logger.info("Generating TAP Schema")
        vodmlFiles.forEach {
            val shortname = it.nameWithoutExtension
            val outfile = schemaDir.file("$shortname.tap.xml")
            logger.debug("Generating JSON schema from  ${it.name} to ${outfile.get().asFile.absolutePath}")
            Vodml2TAP.doTransform(it.absoluteFile, mapOf(
                "binding" to allBinding.joinToString(separator = ",") { it.toURI().toURL().toString() }
            ),
                actualCatalog, outfile.get().asFile)
        }


    }
}