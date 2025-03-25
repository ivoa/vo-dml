package net.ivoa.vodml.gradle.plugin

import org.gradle.api.DefaultTask
import org.gradle.api.Project
import org.gradle.api.file.ArchiveOperations
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.tasks.*
import java.io.File
import java.net.URI
import java.net.URLEncoder
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Paths
import java.nio.file.StandardCopyOption
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
         val pu_name = vodmlFiles.files.first().nameWithoutExtension
         vodmlFiles.forEach { v ->
             val shortname = v.nameWithoutExtension
             val outfile = javaGenDir.file("$shortname.javatrans.txt")
             Vodml2Java.doTransform(
                 v.absoluteFile, mapOf(
                     "binding" to allBinding.joinToString(separator = ",") { it.toURI().toURL().toString() },
                     "output_root" to javaGenDir.get().asFile.toURI().toURL().toString(),
                     "isMain" to (if (index++ == 0) "True" else "False"), // first is the Main
                     "pu_name" to pu_name
                 ),
                 actualCatalog, outfile.get().asFile
             )

         }

         //load the vocabs locally
         fun loadVocab(url:String) {
             logger.debug("loading vocab $url")
             val client = HttpClient.newBuilder().followRedirects(HttpClient.Redirect.NORMAL).build();

             // read the vocabulary in the 'desise' format
             val uri = URI.create(url)
             val request = HttpRequest.newBuilder()
                 .uri(uri)
                 .header("Accept", "application/x-desise+json")
                 .GET()
                 .build();
             val response = client.send(request, HttpResponse.BodyHandlers.ofString());

             // Check if the response is OK (status code 200)
             if (response.statusCode() != 200) {
                 throw  RuntimeException("cannot load vocabulary : " + response.statusCode());
             }
             val out = javaGenDir.file(URLEncoder.encode(uri.toString(), StandardCharsets.UTF_8)).get().asFile
             out.bufferedWriter().use { wout ->
                 wout.write(response.body());
             }


         }
         fun loadLocalVocab(location: String) {

             val inpath = vocabularyDir.file(location.substringAfterLast(':')+".json").get().asFile.toPath()
             logger.info("loading local Vocab $inpath")
             val outpath = javaGenDir.file(URLEncoder.encode(location, StandardCharsets.UTF_8)).get().asFile.toPath()
             Files.copy(inpath, outpath, StandardCopyOption.REPLACE_EXISTING)

         }
         fun loadVocabs (file:File) {
             file.bufferedReader().useLines { lines ->
                 lines.forEach { line ->
                     when {
                         // local vocabs have the form urn:vo-dml:MyModel!vocab:myvocab
                       line.startsWith("urn:vo-dml:") -> loadLocalVocab(line)
                         else -> loadVocab(line)
                     }
                 }
             }
         }

         logger.debug("loading vocabularies")
         loadVocabs(javaGenDir.file("vocabularies.txt").get().asFile)

     }



 }

