import os
from pathlib import Path, PurePath
from saxonche import PySaxonProcessor,PyXdmAtomicValue
from importlib import resources as impresources
from vodmltools import schxslt
from vodmltools import xslt
from vodmltools.vodml import VodmlSchematron


class Schematron:

# note the schematron compile is now done as part of the install so that

    def __init__(self, catalog):
        VodmlSchematron.setCatalog(catalog)        

    def validate(self,file):
        res = VodmlSchematron.doTransformToString(file,params={})
        print(res)

