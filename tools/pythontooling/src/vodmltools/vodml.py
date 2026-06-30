import os
from pathlib import Path, PurePath
from saxonche import PySaxonProcessor, PyXdmAtomicValue, PyXslt30Processor, PyXsltExecutable
from importlib import resources as impresources
from vodmltools import xslt

class XSLTTransformer:

    def __init__(self, script: str, method: str) -> None:
        self.proc: PySaxonProcessor = PySaxonProcessor(license=False)
        self.script: str = script
        self.method: str = method
        self.xsltproc: PyXslt30Processor
        self.executable: PyXsltExecutable

    def setCatalog(self, catalog: str | Path) -> None:
        self.proc.set_catalog_files([os.path.abspath(catalog)])# TODO this does not seem to be picked up properly
        self.xsltproc = self.proc.new_xslt30_processor() # unfortunately compared to the java version the catalog has to be set before stylesheet compilation - so what would otherwise be done in the constuctor is done here.
        inp_file = impresources.files(xslt) / self.script
        self.executable = self.xsltproc.compile_stylesheet(stylesheet_file=str(inp_file))
        self.executable.set_property("!method", self.method)

    def doTransform(self, file: str | Path, params: dict[str, str], output: str | Path) -> None:
        for key, value in params.items():
            self.executable.set_parameter(key, self.proc.make_string_value(value)) # TODO not necessarily all strings

        self.executable.transform_to_file(source_file=os.path.abspath(file), output_file=os.path.abspath(output))

    def doTransformToString(self, file: str | Path, params: dict[str, str]) -> str:
        """Transform and return result as a string instead of writing to file."""
        for key, value in params.items():
            self.executable.set_parameter(key, self.proc.make_string_value(value))

        return self.executable.transform_to_string(source_file=os.path.abspath(file))


class XSLTExecutionOnlyTransformer:
    """A transformer that calls a named template rather than transforming a source document."""

    def __init__(self, script: str, template_name: str) -> None:
        self.proc: PySaxonProcessor = PySaxonProcessor(license=False)
        self.script: str = script
        self.template_name: str = template_name
        self.xsltproc: PyXslt30Processor
        self.executable: PyXsltExecutable

    def setCatalog(self, catalog: str | Path) -> None:
        self.proc.set_catalog_files([os.path.abspath(catalog)])
        self.xsltproc = self.proc.new_xslt30_processor()
        inp_file = impresources.files(xslt) / self.script
        self.executable = self.xsltproc.compile_stylesheet(stylesheet_file=str(inp_file))

    def doTransform(self, params: dict[str, str]) -> str:
        for key, value in params.items():
            self.executable.set_parameter(key, self.proc.make_string_value(value))

        return self.executable.call_template_returning_string(self.template_name)


Vodml2Gml = XSLTTransformer("vo-dml2gml.xsl", "xml")
Vodml2Gvd = XSLTTransformer("vo-dml2gvd.xsl", "text")
Vodml2Html = XSLTTransformer("vo-dml2html.xsl", "html")
Vodml2rdf = XSLTTransformer("vo-dml2rdf.xsl", "text")
Vodml2xsd = XSLTTransformer("vo-dml2xsd.xsl", "xml")

Vodml2xsdNew = XSLTTransformer("vo-dml2xsdNew.xsl", "xml")

Vodml2Java = XSLTTransformer("vo-dml2java.xsl", "text")
Vodml2Latex = XSLTTransformer("vo-dml2Latex.xsl", "text")
Vodml2Vodsl = XSLTTransformer("vo-dml2dsl.xsl", "text")
Vodml2Python = XSLTTransformer("vo-dml2python.xsl", "text")
Xsd2Vodsl = XSLTTransformer("xsd2dsl.xsl", "text")
Vodml2json = XSLTTransformer("vo-dml2jsonschema.xsl", "text")
Vodml2Catalogues = XSLTExecutionOnlyTransformer("create-catalogues.xsl", "main")

Vodml2md = XSLTTransformer("vo-dml2md.xsl", "text")
Vodml2TAP = XSLTTransformer("vo-dml2tap.xsl", "xml")
VodmlSchematron = XSLTTransformer("schematron.xsl", "text")
TapSchema2PlantUML = XSLTTransformer("tapSchema2plantuml.xslt", "text")

def createCatalog(cat: str | Path, vodmlFiles: list[str | Path]) -> None:
    with open(cat, "w") as f:
        f.write("""<?xml version="1.0"?>
                     <catalog  xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog">
                        <group  prefer="system"  >
                        
                """)
        for v in vodmlFiles:
            p = PurePath(os.path.abspath(v))
            f.write(f"   <uri name=\"{p.name}\" uri=\"{p.as_uri()}\"/>\n")
        csf = "common-structure-functions.xsl"
        pos = impresources.files(xslt) / csf
        f.write(f"   <uri name=\"{csf}\" uri=\"{pos.as_uri()}\"/>\n")
        f.write("""
                        </group>
                     </catalog>
                 """)