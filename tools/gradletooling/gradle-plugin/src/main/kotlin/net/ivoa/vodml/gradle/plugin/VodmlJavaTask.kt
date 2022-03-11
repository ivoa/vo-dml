package net.ivoa.vodml.gradle.plugin

import org.apache.tools.ant.types.PatternSet
import org.gradle.api.DefaultTask
import org.gradle.api.file.ArchiveOperations
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.tasks.*
import java.io.File
import java.util.jar.JarInputStream
import javax.inject.Inject


/*
 * Generates java code from the VO-DML models.
 * Created on 04/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */

 open class VodmlJavaTask @Inject constructor(private val ao: ArchiveOperations) : DefaultTask()
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
     fun doGeneration() {
         logger.info("Generating Java for VO-DML files ${vodmlFiles.files.joinToString { it.name }}")
         logger.info("Looked in ${vodmlDir.get()}")
         val externalModelJars = project.configurations.getByName("runtimeClasspath").files.filter (hasVodml)
         logger.info("external models=${externalModelJars.joinToString { f->f.name }}")
         val extBinding = externalModelJars.flatMap{ f ->
             ao.zipTree(f).matching(org.gradle.api.tasks.util.PatternSet().include(bindingFileName(f))).files
         }
         val allBinding  = bindingFiles.files.plus(extBinding)

         externalModelJars.forEach{
            val ft = ao.zipTree(it).matching(org.gradle.api.tasks.util.PatternSet().include(bindingFileName(it)))
         }

         vodmlFiles.forEach{  v ->
             val shortname = v.nameWithoutExtension
             val outfile = javaGenDir.file("$shortname.javatrans.txt")
             Vodml2Java.doTransform(v.absoluteFile, mapOf(
                 "binding" to allBinding.joinToString(separator = ","){it.absolutePath},
                 "output_root" to javaGenDir.get().asFile.absolutePath
             ),
                 catalogFile.get().asFile, outfile.get().asFile)
         }
     }
     private val hasVodml = fun (f: File): Boolean {
         val js = JarInputStream(f.inputStream())
         return (js.manifest.mainAttributes.getValue("VODML-binding") ) != null //IMPL because of weird map of maps no contains
     }

     private val bindingFileName = fun (f: File): String {
         val js = JarInputStream(f.inputStream())
         return (js.manifest.mainAttributes.getValue("VODML-binding") )
     }
 }