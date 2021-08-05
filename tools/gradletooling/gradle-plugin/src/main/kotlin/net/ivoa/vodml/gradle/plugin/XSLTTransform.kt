package net.ivoa.vodml.gradle.plugin


import org.slf4j.LoggerFactory
import net.sf.saxon.s9api.Processor
import net.sf.saxon.s9api.QName
import net.sf.saxon.s9api.Serializer
import net.sf.saxon.s9api.XdmAtomicValue
import java.io.File
import javax.xml.transform.URIResolver
import javax.xml.transform.stream.StreamSource


/*
 * Created on 27/07/2021 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */
abstract class XSLTTransformer( val script: String,  val method: String) {

    private val logger = LoggerFactory.getLogger(this.javaClass.name)

    fun doTransform(vodmlFile: File,  output: File) {
        doTransform(vodmlFile,  emptyMap(), output)
    }
    fun doTransform(vodmlFile: File, params: Map<String,String>, output: File) {


        //TODO push some of this to static construction?
        val processor = Processor(false)
        val defaultResolver: URIResolver = processor.underlyingConfiguration.uriResolver
        processor.underlyingConfiguration.setURIResolver { href, base ->
            logger.debug("XSLT Transform uri resolver href={} base={}", href, base)
            if (base.isBlank()) //IMPL is this the correct heuristic?
                StreamSource(this::class.java.getResourceAsStream("/xslt/$href"))
            else
                defaultResolver.resolve(href, base)
        }
        val compiler = processor.newXsltCompiler()
        val streamSource = StreamSource(this::class.java.getResourceAsStream("/xslt/$script"))
        val stylesheet = compiler.compile(streamSource)
        val out = processor.newSerializer(output)
        out.setOutputProperty(Serializer.Property.METHOD, method)
        out.setOutputProperty(Serializer.Property.INDENT, "yes")
        val trans = stylesheet.load30()
        val sparams = params.entries.associate{
           QName(it.key) to XdmAtomicValue(it.value)
        }
        trans.setStylesheetParameters(sparams)
        trans.transform(StreamSource(vodmlFile), out)
    }

}

object Vodml2Gml : XSLTTransformer("vo-dml2gml.xsl", "xml")
object Vodml2Gvd : XSLTTransformer("vo-dml2gvd.xsl", "text")
object Vodml2Html : XSLTTransformer("vo-dml2html.xsl", "html")
object Vodml2rdf : XSLTTransformer("vo-dml2rdf.xsl", "text")
object Vodml2xsd : XSLTTransformer("vo-dml2xsd.xsl", "xml")
object Vodml2Java : XSLTTransformer("vo-dml2pojo.xsl", "text")
