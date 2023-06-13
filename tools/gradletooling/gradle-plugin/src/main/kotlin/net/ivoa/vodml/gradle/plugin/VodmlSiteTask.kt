package net.ivoa.vodml.gradle.plugin

import org.gradle.api.file.ArchiveOperations
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.*
import java.io.File
import java.util.concurrent.TimeUnit
import javax.inject.Inject


/*
 * Created on 04/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */
/**
 * task to create documentation for VO-DML.
 */
 open class VodmlSiteTask  @Inject constructor(ao1: ArchiveOperations) : VodmlBaseTask(ao1)
 {
     @get:OutputDirectory
     val docDir : DirectoryProperty = project.objects.directoryProperty()

     @Input @Optional
     val modelsToDocument : Property<String> = project.objects.property(String::class.java)

     @TaskAction
     fun doDocumentation() {
         logger.info("Creating site for VO-DML models ${vodmlFiles.files.joinToString { it.name }}")
         logger.info("Looked in ${vodmlDir.get()}")
         val eh = ExternalModelHelper(project, ao, logger)
         val actualCatalog = eh.makeCatalog(vodmlFiles,catalogFile)
         val allBinding = bindingFiles.files.plus(eh.externalBinding())

         vodmlFiles.forEach{
             val shortname = it.nameWithoutExtension
             logger.info("doing graphviz generation")
             var outfile = docDir.file(shortname +".gvd")
             Vodml2Gvd.doTransform(it.absoluteFile, mapOf("mode" to "md"),
                 actualCatalog, outfile.get().asFile)

             val proc = ProcessBuilder(listOf(
                 "dot",
                 "-Tsvg",
                 "-o${shortname +".svg"}",
                 outfile.get().asFile.absolutePath
             ))
                 .directory(docDir.get().asFile)
                 .redirectOutput(ProcessBuilder.Redirect.PIPE)
                 .redirectError(ProcessBuilder.Redirect.PIPE)
                 .start()

             proc.waitFor(5, TimeUnit.SECONDS)

             logger.info(proc.inputStream.bufferedReader().readText())
             if (proc.exitValue() != 0)
                 logger.error(proc.errorStream.bufferedReader().readText())

             outfile = docDir.file("$shortname.md")
             Vodml2md.doTransform(it.absoluteFile, mapOf("graphviz_png" to docDir.file("$shortname.svg").get().asFile.absolutePath,
                 "binding" to allBinding.joinToString(separator = ",") { it.absolutePath },
             ),
                 actualCatalog, outfile.get().asFile)
             outfile = docDir.file("$shortname.graphml")
             Vodml2Gml.doTransform(it.absoluteFile, emptyMap(), actualCatalog, outfile.get().asFile)


         }

     }


 }