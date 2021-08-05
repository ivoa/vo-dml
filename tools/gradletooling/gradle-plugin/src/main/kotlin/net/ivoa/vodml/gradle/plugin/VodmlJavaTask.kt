package net.ivoa.vodml.gradle.plugin

import org.gradle.api.DefaultTask
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.tasks.*


/*
 * Generates java code from the VO-DML models.
 * Created on 04/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */

 open class VodmlJavaTask : DefaultTask()
 {
     @get:[InputDirectory PathSensitive(PathSensitivity.RELATIVE)]
     val vodmlDir: DirectoryProperty = project.objects.directoryProperty()

     @get:InputFiles
     val vodmlFiles: ConfigurableFileCollection = project.objects.fileCollection()

     @get:OutputDirectory
     val docDir : DirectoryProperty = project.objects.directoryProperty()

     @TaskAction
     fun doDocumentation() {
         logger.info("Generating Java for VO-DML files ${vodmlFiles.files.joinToString { it.name }}")
         logger.info("Looked in ${vodmlDir.get()}")

         vodmlFiles.forEach{
             val shortname = it.nameWithoutExtension
             val outfile = docDir.file(shortname +".html")
             Vodml2Html.doTransform(it.absoluteFile, outfile.get().asFile)
         }

     }


 }