package net.ivoa.vodml.gradle.plugin


import net.sf.saxon.s9api.Processor
import net.sf.saxon.s9api.QName
import net.sf.saxon.s9api.Serializer
import net.sf.saxon.s9api.XdmAtomicValue
import org.slf4j.LoggerFactory
import org.xml.sax.InputSource
import org.xmlresolver.CatalogResolver
import org.xmlresolver.ResolverFeature
import org.xmlresolver.XMLResolverConfiguration
import org.xmlresolver.sources.ResolverSAXSource
import java.io.File
import java.net.URI
import java.net.URL
import javax.xml.transform.Source
import javax.xml.transform.URIResolver
import javax.xml.transform.stream.StreamSource


/*
 * Created on 27/07/2021 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */
abstract class XSLTTransformer( val script: String,  val method: String) {

    private val logger = LoggerFactory.getLogger(this.javaClass.name)

    init {
        logger.info("initializing transformer for ${script}")
    }

    fun doTransform(vodmlFile: File,  output: File) {
        doTransform(vodmlFile,  emptyMap(), output)
    }
    fun doTransform(vodmlFile: File, params: Map<String,String>, output: File) {
        logger.info("doing $script transform with params")
        params.forEach{
            logger.info("parameter ${it.key}, val=${it.value}")
        }



        //TODO push some of this to static construction?
        val processor = Processor(false)
        val defaultResolver: URIResolver = processor.underlyingConfiguration.uriResolver
        processor.underlyingConfiguration.setURIResolver { href, base ->
            logger.info("XSLT Transform uri resolver href={} base={}", href, base)
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

        val config = XMLResolverConfiguration()
        config.setFeature(ResolverFeature.PREFER_PUBLIC, false)
        config.setFeature(ResolverFeature.CATALOG_FILES, listOf("/Users/pharriso/Work/ivoa/vo-dml/tools/catalog.xml" ))
        config.setFeature(ResolverFeature.URI_FOR_SYSTEM, true) // fall through to URI
        val catalogResolver = CatalogResolver(config)
        trans.uriResolver = VodmlResolver(catalogResolver)
        trans.transform(StreamSource(vodmlFile), out)
    }

}

class VodmlResolver(catres: CatalogResolver) : org.xmlresolver.Resolver(catres)
{
    private val logger = LoggerFactory.getLogger(this.javaClass.name)
    override fun resolve(href: String?, base: String?): Source {
        logger.info("vodml resolver $href base=$base")
        val original =  super.resolve(href, base)
        if (original == null) {
            logger.info("not in catalogue")
            val absolute = if(base?.isBlank()!!) URI(base).resolve(href) else URI(href)
            val url = try {
                absolute.toURL()
            } catch (e: Exception) {
                logger.info("first error ${e.toString()}")
                try {
                    File(absolute.path).toURI().toURL()
                } catch (e: Exception) {
                    logger.info("second error ${e.toString()}")
                    URL("?")
                }
            }
            return try {
                val source =
                    ResolverSAXSource(absolute, InputSource(url.openStream()))
                source.systemId = absolute.toString()
                logger.info("got here? ${source.toString()}")
                source
            } catch (e: Exception) {
                logger.error("xxx ${e.toString()}")
                ResolverSAXSource(absolute,null)
            }


        }
        else {
            return original
        }


    }


}

object Vodml2Gml : XSLTTransformer("vo-dml2gml.xsl", "xml")
object Vodml2Gvd : XSLTTransformer("vo-dml2gvd.xsl", "text")
object Vodml2Html : XSLTTransformer("vo-dml2html.xsl", "html")
object Vodml2rdf : XSLTTransformer("vo-dml2rdf.xsl", "text")
object Vodml2xsd : XSLTTransformer("vo-dml2xsd.xsl", "xml")
object Vodml2Java : XSLTTransformer("vo-dml2java.xsl", "text")
