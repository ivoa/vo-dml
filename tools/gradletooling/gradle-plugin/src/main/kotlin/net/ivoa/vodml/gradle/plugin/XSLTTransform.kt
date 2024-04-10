package net.ivoa.vodml.gradle.plugin


import net.sf.saxon.s9api.Processor
import net.sf.saxon.s9api.QName
import net.sf.saxon.s9api.Serializer
import net.sf.saxon.s9api.XdmAtomicValue
import net.sf.saxon.s9api.XsltExecutable
import org.gradle.api.GradleException
import org.slf4j.LoggerFactory
import org.xmlresolver.XMLResolver
import org.xmlresolver.ResolverFeature
import org.xmlresolver.XMLResolverConfiguration
import java.io.File
import javax.xml.transform.URIResolver
import javax.xml.transform.stream.StreamSource


/**
 * Runs XSLT transformations.
 * Created on 27/07/2021 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */
abstract class BaseTransformer( val script: String ) {
    protected val logger = LoggerFactory.getLogger(this.javaClass.name)
    protected val processor : Processor
    protected val defaultResolver: URIResolver
    protected val stylesheet: XsltExecutable
    init {
        logger.debug("initializing transformer for ${script}")
        processor = Processor(false)
        defaultResolver = processor.underlyingConfiguration.uriResolver
        processor.underlyingConfiguration.setURIResolver { href, base ->
            logger.debug("XSLT Transform uri resolver href={} base={}", href, base)
            if (base.isBlank()) //IMPL is this the correct heuristic?
                StreamSource(this::class.java.getResourceAsStream("/xslt/$href"))
            else
                defaultResolver.resolve(href, base)
        }
        val compiler = processor.newXsltCompiler()
        val streamSource = StreamSource(this::class.java.getResourceAsStream("/xslt/$script"))
        stylesheet = compiler.compile(streamSource)
    }

}

 open class XSLTTransformer( val xslscript: String,  val method: String) : BaseTransformer(xslscript) {


    fun doTransform(vodmlFile: File,  output: File) {
        doTransform(vodmlFile,  emptyMap(), null, output)
    }
    fun doTransform(vodmlFile: File,  params: Map<String,String> ,output: File) {
        doTransform(vodmlFile, params, null, output)
    }
    fun doTransform(vodmlFile: File, params: Map<String,String>, catalog: File?, output: File) {
        logger.debug("doing $script transform with params")
        params.forEach{
            logger.debug("parameter ${it.key}, val=${it.value}")
        }
        if(!vodmlFile.exists())
        {
            throw GradleException("input file "+vodmlFile+ " does not exist")
        }


        val out = processor.newSerializer(output)
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
        trans.uriResolver = resolver.getURIResolver()
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
