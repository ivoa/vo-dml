import os
from setuptools import setup
from setuptools.command.build_py import build_py
from pathlib import Path
from urllib.request import urlretrieve
import zipfile
from saxonche import PySaxonProcessor,PyXdmAtomicValue


class CustomBuildPy(build_py):
    def run(self):
        super().run()
        print("downloading schxslt editable=" + str(self.editable_mode))
        SCHXSLTVER = "1.11.1"
        url = f"https://codeberg.org/SchXslt/schxslt2/releases/download/v{SCHXSLTVER}/schxslt2-{SCHXSLTVER}.zip"
        print("downloading schxslt from " + url)
        schzip, headers = urlretrieve(url)

        if self.editable_mode:
            extract_base = Path("src/vodmltools")
        else:
            extract_base = Path(self.build_lib) / "vodmltools"

        extract_base.mkdir(parents=True, exist_ok=True)

        zf = zipfile.ZipFile(schzip)
        for f in zf.namelist():
            if not f.endswith("/"):
                zf.extract(f, path=extract_base)

        extracted = extract_base / f"schxslt2-{SCHXSLTVER}"
        target = extract_base / "schxslt"
        if target.exists():
            import shutil
            shutil.rmtree(target)
        os.rename(extracted, target)
        print("compiling the schematron")
        proc = PySaxonProcessor(license=False)
        xsltproc = proc.new_xslt30_processor()
        inp_file = target / "transpile.xsl"
        xslbase = extract_base / "xslt"
        schematron_pipeline = xsltproc.compile_stylesheet(stylesheet_file=str(inp_file))
        schematron_pipeline.set_cwd(str(xslbase))
        schematron_pipeline.transform_to_file(source_file="vo-dml-v1.0.sch.xml",output_file="schematron.xsl")



setup(
    cmdclass={
        'build_py': CustomBuildPy,
    }
)