package net.ivoa.vodml.gradle.plugin

import org.gradle.api.DefaultTask
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.*
import java.io.File
import java.time.ZoneOffset
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter


/*
 * Created on 18/02/2022 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */
/**
 * task to transform UML represented as XMI into VO-DML.
 */
open class XmiTask : DefaultTask() {

    @get:Input
    val xmiScript: Property<String> = project.objects.property(String::class.java)

    @get:Input @Optional
    val xsdNsPrefix: Property<String> = project.objects.property(String::class.java).convention("xsd")

    @get:InputFile
    val xmiFile: RegularFileProperty = project.objects.fileProperty()

    @get:OutputFile
    val vodmlFile: RegularFileProperty = project.objects.fileProperty()

    private val utypeConverter =  XSLTTransformer("generate-utypes4vo-dml.xsl", "xml")

    @TaskAction
    fun doXmiToVodml(){
        val xmiConverter =  XSLTTransformer(xmiScript.get(), "xml") //IMPL might be nicer to have this created at construction, but then the look of the task in build file more complex
        logger.info("Generating VO-DML   ${vodmlFile.get().asFile.absolutePath} from XMI ${xmiFile.get().asFile.absolutePath}")
        val tmpfile = File.createTempFile("xmi","xml",temporaryDir)
        //IMPL - not sure that the map parameters really covers use - there are others, but it seems not really used.
        xmiConverter.doTransform(xmiFile.get().asFile.absoluteFile, mapOf("vodmlSchemaNS" to "http://www.ivoa.net/xml/VODML/v1" ,
                                                                          "lastModifiedXSDDatetime" to ZonedDateTime.now( ZoneOffset.UTC ).format( DateTimeFormatter.ISO_INSTANT )),tmpfile.absoluteFile)
        utypeConverter.doTransform(tmpfile.absoluteFile,vodmlFile.get().asFile.absoluteFile)
    }
}