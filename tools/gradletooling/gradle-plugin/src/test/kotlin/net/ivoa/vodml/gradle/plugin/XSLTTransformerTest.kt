package net.ivoa.vodml.gradle.plugin

import org.junit.jupiter.api.BeforeEach
import java.io.File

/*
 Ony really tests whether the xsl transforms run without exception.
 * Created on 03/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */

internal class XSLTTransformerTest {
    private val model= File(System.getProperty("GRADLE_ROOT_FOLDER"), "../../../models/ivoa/vo-dml/IVOA-v1.0.vo-dml.xml")
    private val binding = File(System.getProperty("GRADLE_ROOT_FOLDER"), "../../../models/ivoa/vo-dml/ivoa_base.vodml-binding.xml")
    private val tmpDir = File(System.getProperty("GRADLE_BUILD_FOLDER"),"tmp/junit/")
    @BeforeEach
    internal fun setUp() {

    }

    @org.junit.jupiter.api.Test
    fun doGml() {
        Vodml2Gml.doTransform(model, File(tmpDir,"testgml.xml"))
    }
    @org.junit.jupiter.api.Test
    fun doGvd() {
        Vodml2Gvd.doTransform(model, File(tmpDir,"testgvd.xml"))
    }
    @org.junit.jupiter.api.Test
    fun doHtml() {
        Vodml2Html.doTransform(model, File(tmpDir,"testhtml.html"))
    }
    @org.junit.jupiter.api.Test
    fun doRdf() {
        Vodml2rdf.doTransform(model, File(tmpDir,"testtdf.rdf"))
    }
    @org.junit.jupiter.api.Test
    fun doVodsl() {
        Vodml2Vodsl.doTransform(model, File(tmpDir,"testvodsl.vodsl"))
    }
//    @org.junit.jupiter.api.Test
//    fun doXsd() { //the xsd generation is not a straight model transform TODO would need a catalogue
//        Vodml2xsd.doTransform(model, mapOf(
//            "binding" to binding.absolutePath
//        ), File(tmpDir,"testxsd.xsd"))
//    }
}