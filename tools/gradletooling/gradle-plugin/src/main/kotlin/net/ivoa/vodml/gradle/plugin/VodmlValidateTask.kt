package net.ivoa.vodml.gradle.plugin

import name.dmaus.schxslt.Schematron
import org.gradle.api.file.ArchiveOperations
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.tasks.*
import org.xmlresolver.XMLResolver
import org.xmlresolver.ResolverFeature
import org.xmlresolver.XMLResolverConfiguration
import javax.inject.Inject
import javax.xml.transform.stream.StreamSource
import org.ivoa.vodml.validation.XMLValidator
import java.io.StringWriter
import org.gradle.api.GradleException


/*
 * Created on 04/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk).
 */
/**
 * Validates VO-DML moddels.
 */
 open class VodmlValidateTask @Inject constructor( ao1: ArchiveOperations) : VodmlBaseTask(ao1)
 {

     @get:[OutputDirectory]
     val docDir : DirectoryProperty = project.objects.directoryProperty()


     @TaskAction
     fun doValidation() {
         logger.info("Validating VO-DML files ${vodmlFiles.files.joinToString { it.name }}")
         logger.info("Looked in ${vodmlDir.get()}")

         val config = XMLResolverConfiguration()
         val eh = ExternalModelHelper(project, ao, logger)
         val actualCatalog = eh.makeCatalog(vodmlFiles,catalogFile)

         config.setFeature(ResolverFeature.CATALOG_FILES, listOf(actualCatalog.absolutePath))

         config.setFeature(ResolverFeature.PREFER_PUBLIC, false)

         config.setFeature(ResolverFeature.URI_FOR_SYSTEM, true) // fall through to URI

         config.setFeature(ResolverFeature.MASK_JAR_URIS, false) // needed for classpath to work in the catalog for schematron include
         val resolver = XMLResolver(config)

         val transformerFactory = net.sf.saxon.TransformerFactoryImpl()
         transformerFactory.uriResolver = resolver.getURIResolver()

         val schematron = Schematron(StreamSource(this::class.java.getResourceAsStream("/xslt/vo-dml-v1.0.sch.xml")), null,
             transformerFactory, HashMap())




         vodmlFiles.forEach{
             val shortname = it.nameWithoutExtension
             val vodmlvalidator = XMLValidator()
             val vodmlresult = vodmlvalidator.validate(it.absoluteFile)
             if(!vodmlresult.isOk)
             {
                 val sw = StringWriter()
                 vodmlresult.printValidationErrors(sw)
                 throw  GradleException("${it} has XML errors\n ${sw.toString()}") // early exit as fatal error.
             }
             //val outfile = docDir.file(shortname +".validation")
             val result = schematron.validate(StreamSource(it.absoluteFile))
             logger.info("Validating $shortname, result valid=${result.isValid}")
             if (!result.isValid)
             {
                 //TODO should probably signal error to the task output...
                 result.validationMessages.forEach { it2 -> logger.error(it2) }
             }

         }

     }


 }