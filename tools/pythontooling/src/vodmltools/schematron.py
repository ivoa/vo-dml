import os
from pathlib import Path, PurePath
from saxonche import PySaxonProcessor,PyXdmAtomicValue
from importlib import resources as impresources
from vodmltools import schxslt
from vodmltools import xslt


class Schematron:
    def __init__(self):
        self.proc = PySaxonProcessor(license=False)
        self.proc.set_catalog_files([os.path.abspath("tmpcat.xml")])
        self.xsltproc = self.proc.new_xslt30_processor()
        inp_file = impresources.files(schxslt) / "pipeline-for-svrl.xsl"
        self.schematron_pipeline = self.xsltproc.compile_stylesheet(stylesheet_file=str(inp_file))
        inp_rules = impresources.files(xslt) / "vo-dml-v1.0.sch.xml"
        sch = self.schematron_pipeline.transform_to_string(source_file=str(inp_rules))
        self.rules = self.xsltproc.compile_stylesheet(stylesheet_text=sch)
        self.normalize = self.xsltproc.compile_stylesheet(stylesheet_file=str(impresources.files(schxslt) / "util/normalize-svrl.xsl"))

    def validate(self,file):
        res = self.rules.transform_to_string(source_file=file)
        print(res)

