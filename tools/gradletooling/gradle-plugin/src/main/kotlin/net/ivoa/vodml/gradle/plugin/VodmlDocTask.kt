package net.ivoa.vodml.gradle.plugin

import org.gradle.api.DefaultTask
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.*
import java.util.concurrent.TimeUnit


/*
 * Created on 04/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */

 open class VodmlDocTask : DefaultTask()
 {
     @get:[InputDirectory PathSensitive(PathSensitivity.RELATIVE)]
     val vodmlDir: DirectoryProperty = project.objects.directoryProperty()

     @get:InputFiles
     val vodmlFiles: ConfigurableFileCollection = project.objects.fileCollection()

     @get:InputFile
     val catalogFile: RegularFileProperty = project.objects.fileProperty()

     @get:OutputDirectory
     val docDir : DirectoryProperty = project.objects.directoryProperty()

     @Input @Optional
     val modelsToDocument : Property<String> = project.objects.property(String::class.java)

     @TaskAction
     fun doDocumentation() {
         logger.info("Documenting VO-DML files ${vodmlFiles.files.joinToString { it.name }}")
         logger.info("Looked in ${vodmlDir.get()}")

         vodmlFiles.forEach{
             val shortname = it.nameWithoutExtension
             var outfile = docDir.file(shortname +".html")
             Vodml2Html.doTransform(it.absoluteFile, outfile.get().asFile)
             outfile = docDir.file(shortname +".graphml")
             Vodml2Gml.doTransform(it.absoluteFile, emptyMap(), catalogFile.get().asFile, outfile.get().asFile)
             outfile = docDir.file(shortname +"_desc.tex" )
             val params = if (modelsToDocument.isPresent) mapOf("modelsToDocument" to modelsToDocument.get()) else emptyMap()
             Vodml2Latex.doTransform(it.absoluteFile, params, catalogFile.get().asFile, outfile.get().asFile)
             logger.info("doing graphviz generation")
             outfile = docDir.file(shortname +".gvd")
             Vodml2Gvd.doTransform(it.absoluteFile, outfile.get().asFile)
             val proc = ProcessBuilder(listOf(
                 "dot",
                 "-Tcmapx",
                 "-o${shortname +".map"}",
                  "-Tpng",
                 "-o${shortname +".png"}",
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

         }

     }


 }