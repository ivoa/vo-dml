package net.ivoa.vodml.gradle.plugin

import net.sf.saxon.s9api.SaxonApiException
import net.sf.saxon.s9api.SaxonApiUncheckedException
import net.sf.saxon.s9api.Processor
import net.sf.saxon.s9api.QName
import net.sf.saxon.s9api.Serializer
import net.sf.saxon.s9api.XdmAtomicValue
import net.sf.saxon.s9api.XsltExecutable
import net.sf.saxon.lib.ResourceResolver
import org.gradle.api.GradleException
import org.slf4j.LoggerFactory
import org.xmlresolver.XMLResolver
import org.xmlresolver.ResolverFeature
import org.xmlresolver.XMLResolverConfiguration
import java.io.File
import java.io.StringWriter
import javax.xml.transform.stream.StreamSource


/**
 * Runs XSLT transformations.
 * Created on 27/07/2021 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */
abstract class BaseTransformer( val script: String ) {
    protected val logger = LoggerFactory.getLogger(this.javaClass.name)
    protected val processor : Processor
    protected val defaultResolver: ResourceResolver
    protected val stylesheet: XsltExecutable
    init {
        logger.info("initializing transformer for ${script}")
        processor = Processor(false)
        defaultResolver = processor.underlyingConfiguration.resourceResolver
        processor.underlyingConfiguration.setResourceResolver { href -> //IMPL perhaps should use on of the classes from https://www.saxonica.com/documentation12/index.html#!javadoc/net.sf.saxon.lib/ResourceResolver rather than this anonymous...
            logger.debug("XSLT Transform uri resolver rel={} base={} nature={}", href.relativeUri, href.baseUri, href.nature)
            if(href.relativeUri != null && href.relativeUri.endsWith(".xsl"))//IMPL - only the stylesheets that are in their own dir
                 StreamSource(this::class.java.getResourceAsStream("/xslt/${href.relativeUri}"))
            else
                defaultResolver.resolve(href)
        }
        val compiler = processor.newXsltCompiler()
        val streamSource = StreamSource(this::class.java.getResourceAsStream("/xslt/$script"))
        try {
            stylesheet = compiler.compile(streamSource)
        }// attempt to get any compilation errors printed out - gradle tends to swallow the messages
        catch (e:SaxonApiException)
        {
            logger.error(e.toString())
            throw  SaxonApiException("error compiling {$script}",e)
        }
        catch (e:SaxonApiUncheckedException)
        {
            logger.error(e.toString())
            throw  SaxonApiException("error compiling {$script}",e)
        }

    }

}

 open class XSLTTransformer( val xslscript: String,  val method: String) : BaseTransformer(xslscript) {


    fun doTransform(vodmlFile: File,  output: File) {
        doTransform(vodmlFile,  emptyMap(), null, output)
    }
    fun doTransform(vodmlFile: File,  params: Map<String,String> ,output: File) {
        doTransform(vodmlFile, params, null, output)
    }

     fun doTransform(vodmlFile: File, params: Map<String,String>, catalog: File?, output: File)
     {
         val out = processor.newSerializer(output)
         doTransformInternal(vodmlFile,params,catalog,out)

     }
     fun doTransformToString(vodmlFile: File, params: Map<String,String>, catalog: File?) : String
     {
         val sw = java.io.StringWriter()
         val out = processor.newSerializer(sw)
         doTransformInternal(vodmlFile,params,catalog,out)
         return sw.toString()
     }

    private fun doTransformInternal(vodmlFile: File, params: Map<String,String>, catalog: File?, out: Serializer) {
        logger.debug("doing $script transform with params")
        params.forEach{
            logger.debug("parameter ${it.key}, val=${it.value}")
        }
        if(!vodmlFile.exists())
        {
            throw GradleException("input file "+vodmlFile+ " does not exist")
        }
        out.setOutputProperty(Serializer.Property.METHOD, method)
        out.setOutputProperty(Serializer.Property.INDENT, "yes")
        val trans = stylesheet.load30()
        val sparams = params.entries.associate{
           QName(it.key) to XdmAtomicValue(it.value)
        }
        trans.setStylesheetParameters(sparams)

        val config = XMLResolverConfiguration()
        config.setFeature(ResolverFeature.PREFER_PUBLIC, false)
        if (catalog != null) {
            config.setFeature(ResolverFeature.CATALOG_FILES, listOf(catalog.absolutePath ))
        }
        config.setFeature(ResolverFeature.URI_FOR_SYSTEM, false) // don't automatically use URI as system to prevent surprises
        val resolver = XMLResolver(config)
        trans.uriResolver = resolver.getURIResolver() // TODO this is deprecated but still working in v12 - might be able to get away with just setting the Catalogue files directly on the Saxon Processor - https://www.saxonica.com/documentation12/index.html#!javadoc/net.sf.saxon.lib/CatalogResourceResolver
        trans.transform(StreamSource(vodmlFile), out)
    }


}

/**
 * a transformer that has a stylesheet that only uses xsl:result-document ans starts from the named template.
 */
open class XSLTExecutionOnlyTransformer( val xslscript: String,  val templateName: String) : BaseTransformer(xslscript) {

    fun doTransform(params: Map<String,String>) {
        val trans = stylesheet.load30()
        val sparams = params.entries.associate{
            QName(it.key) to XdmAtomicValue(it.value)
        }
        trans.setStylesheetParameters(sparams)
        val tmp = java.io.File.createTempFile("ignore","silly")
        trans.setBaseOutputURI(tmp.toURI().toString()) // IMPL - not the real output - only done to avoid net.sf.saxon.s9api.SaxonApiException: The system identifier of the principal output file is unknown
        trans.callTemplate(QName(templateName))
    }

}


object Vodml2Gml : XSLTTransformer("vo-dml2gml.xsl", "xml")
object Vodml2Gvd : XSLTTransformer("vo-dml2gvd.xsl", "text")
object Vodml2Html : XSLTTransformer("vo-dml2html.xsl", "html")
object Vodml2rdf : XSLTTransformer("vo-dml2rdf.xsl", "text")
object Vodml2xsd : XSLTTransformer("vo-dml2xsd.xsl", "xml")

object Vodml2xsdNew : XSLTTransformer("vo-dml2xsdNew.xsl", "xml")

object Vodml2Java : XSLTTransformer("vo-dml2java.xsl", "text")
object Vodml2Latex : XSLTTransformer("vo-dml2Latex.xsl", "text")
object Vodml2Vodsl : XSLTTransformer("vo-dml2dsl.xsl", "text")
object Vodml2Python : XSLTTransformer("vo-dml2python.xsl", "text")
object Xsd2Vodsl : XSLTTransformer("xsd2dsl.xsl", "text")
object Vodml2json : XSLTTransformer("vo-dml2jsonschema.xsl", "text")
object Vodml2Catalogues : XSLTExecutionOnlyTransformer("create-catalogues.xsl", "main")

object Vodml2md : XSLTTransformer("vo-dml2md.xsl", "text")
object Vodml2TAP : XSLTTransformer("vo-dml2tap.xsl", "xml")
