package net.ivoa.vodml.gradle.plugin

import org.gradle.api.DefaultTask
import org.gradle.api.Project
import org.gradle.api.file.ArchiveOperations
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.tasks.*
import java.io.File
import java.nio.file.Paths
import java.util.jar.JarInputStream
import javax.inject.Inject


/**
 * Generates java code from the VO-DML models.
 * Created on 04/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */

 open class VodmlJavaTask @Inject constructor( ao1: ArchiveOperations) : VodmlBaseTask(ao1) {

     @get:OutputDirectory
     val javaGenDir: DirectoryProperty = project.objects.directoryProperty()

     @TaskAction
     fun doGeneration() {
         logger.info("Generating Java for VO-DML files ${vodmlFiles.files.joinToString { it.name }}")
         logger.info("Looked in ${vodmlDir.get()}")
         val eh = ExternalModelHelper(project, ao, logger)
         val actualCatalog = eh.makeCatalog(vodmlFiles,catalogFile)

         val allBinding = bindingFiles.files.plus(eh.externalBinding())

         var index = 0;
         vodmlFiles.forEach { v ->
             val shortname = v.nameWithoutExtension
             val outfile = javaGenDir.file("$shortname.javatrans.txt")
             Vodml2Java.doTransform(
                 v.absoluteFile, mapOf(
                     "binding" to allBinding.joinToString(separator = ",") { it.absolutePath },
                     "output_root" to javaGenDir.get().asFile.absolutePath,
                     "isMain" to (if (index++ == 0) "True" else "False") // first is the Main
                 ),
                 actualCatalog, outfile.get().asFile
             )
         }
     }
 }

