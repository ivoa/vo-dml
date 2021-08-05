package net.ivoa.vodml.gradle.plugin

import name.dmaus.schxslt.Schematron
import org.gradle.api.DefaultTask
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.tasks.*
import javax.xml.transform.stream.StreamSource


/*
 * Created on 04/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk).
 *FIXME need to understand the schematron more - this is not working with current schematron file
 */

 open class VodmlValidateTask : DefaultTask()
 {
     @get:[InputDirectory PathSensitive(PathSensitivity.RELATIVE)]
     val vodmlDir: DirectoryProperty = project.objects.directoryProperty()

     @get:InputFiles
     val vodmlFiles: ConfigurableFileCollection = project.objects.fileCollection()

     @get:OutputDirectory
     val docDir : DirectoryProperty = project.objects.directoryProperty()

     @TaskAction
     fun doValidation() {
         logger.info("Validating VO-DML files ${vodmlFiles.files.joinToString { it.name }}")
         logger.info("Looked in ${vodmlDir.get()}")

         val schematron = Schematron(StreamSource(this::class.java.getResourceAsStream("/xsd/vo-dml-v1.0.sch.xml")), null, net.sf.saxon.TransformerFactoryImpl(), HashMap())

         vodmlFiles.forEach{
             val shortname = it.nameWithoutExtension
             val outfile = docDir.file(shortname +".validation")
             val result = schematron.validate(StreamSource(it.absoluteFile))
             logger.info("$shortname validation=${result.isValid}")
             TODO("need to do something with the validation result")
         }

     }


 }