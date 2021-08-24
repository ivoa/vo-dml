package net.ivoa.vodml.gradle.plugin

import org.gradle.api.DefaultTask
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.RegularFileProperty
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
     val javaGenDir : DirectoryProperty = project.objects.directoryProperty()

     @get:InputFiles
     val bindingFiles: ConfigurableFileCollection = project.objects.fileCollection()

     @get:InputFile
     val catalogFile: RegularFileProperty = project.objects.fileProperty()

     @TaskAction
     fun doDocumentation() {
         logger.info("Generating Java for VO-DML files ${vodmlFiles.files.joinToString { it.name }}")
         logger.info("Looked in ${vodmlDir.get()}")

         vodmlFiles.forEach{
             val shortname = it.nameWithoutExtension
             val outfile = javaGenDir.file(shortname +".javatrans.txt")
             Vodml2Java.doTransform(it.absoluteFile, mapOf(
                 "binding" to bindingFiles.files.joinToString(separator = ","){it.absolutePath},
                 "output_root" to javaGenDir.get().asFile.absolutePath
             ),
                 catalogFile.get().asFile, outfile.get().asFile)
         }

     }


 }