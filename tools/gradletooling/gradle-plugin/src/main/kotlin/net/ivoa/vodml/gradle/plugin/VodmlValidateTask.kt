package net.ivoa.vodml.gradle.plugin

import name.dmaus.schxslt.Schematron
import org.gradle.api.DefaultTask
import org.gradle.api.file.ArchiveOperations
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.tasks.*
import org.xmlresolver.CatalogResolver
import org.xmlresolver.ResolverFeature
import org.xmlresolver.XMLResolverConfiguration
import javax.inject.Inject
import javax.xml.transform.stream.StreamSource


/*
 * Created on 04/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */

 open class VodmlValidateTask @Inject constructor(private val ao: ArchiveOperations) : DefaultTask()
 {
     @get:[InputDirectory PathSensitive(PathSensitivity.RELATIVE)]
     val vodmlDir: DirectoryProperty = project.objects.directoryProperty()

     @get:InputFiles
     val vodmlFiles: ConfigurableFileCollection = project.objects.fileCollection()

     @get:InputFile @Optional
     val catalog: RegularFileProperty = project.objects.fileProperty()

     @get:[OutputDirectory]
     val docDir : DirectoryProperty = project.objects.directoryProperty()


     @TaskAction
     fun doValidation() {
         logger.info("Validating VO-DML files ${vodmlFiles.files.joinToString { it.name }}")
         logger.info("Looked in ${vodmlDir.get()}")

         val config = XMLResolverConfiguration()
         val eh = ExternalModelHelper(project, ao, logger)
         val actualCatalog = eh.makeCatalog(vodmlFiles,catalog)

         config.setFeature(ResolverFeature.CATALOG_FILES, listOf(actualCatalog.absolutePath))

         config.setFeature(ResolverFeature.PREFER_PUBLIC, false)

         config.setFeature(ResolverFeature.URI_FOR_SYSTEM, true) // fall through to URI
         val catalogResolver = CatalogResolver(config)

         val transformerFactory = net.sf.saxon.TransformerFactoryImpl()
         transformerFactory.uriResolver = org.xmlresolver.Resolver(catalogResolver)

         val schematron = Schematron(StreamSource(this::class.java.getResourceAsStream("/xsd/vo-dml-v1.0.sch.xml")), null,
             transformerFactory, HashMap())



         vodmlFiles.forEach{
             val shortname = it.nameWithoutExtension
             val outfile = docDir.file(shortname +".validation")
             val result = schematron.validate(StreamSource(it.absoluteFile))
             logger.info("$shortname validation=${result.isValid}")
             if (!result.isValid)
             {
                 //TODO should probably signal error to the task output...
                 result.validationMessages.forEach { it2 -> logger.error(it2) }
             }

         }

     }


 }