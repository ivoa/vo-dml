from contextlib import suppress
from setuptools import Command, setup
from setuptools.command.build import build
from pathlib import Path
from urllib.request import urlretrieve
import zipfile,os

class GetSchxslt(Command):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.bdist_dir = None
        self.build_lib = None
        self.editable_mode = False

    def initialize_options(self):
        """Initialize command state to defaults"""
        self.bdist_dir = None

    def finalize_options(self):
        """
        Populate the command state. This is where I traverse the directory
        tree to search for the *.ksc files to compile them later.
        The self.set_undefined_options is used to inherit the `build_lib`
        attribute from the `build_py` command.
        """
        with suppress(Exception):
            self.bdist_dir =Path(self.get_finalized_command("bdist_wheel").bdist_dir)

        ...

    def run(self):
        """
        Perform actions with side-effects, such as invoking a ksc to python compiler.
        The directory to which outputs are written depends on `editable_mode` attribute.
        When editable_mode == False, the outputs are written to directory pointed by build_lib.
        When editable_mode == True, the outputs are written in-place,
        i.e. into the directory containing the sources.
        The `run` method is not executed during sdist builds.
        """
        print("downloading schxslt "+ str(self.editable_mode))
        SCHXSLTVER = "1.10.1"
        url = f"https://github.com/schxslt/schxslt/releases/download/v{SCHXSLTVER}/schxslt-{SCHXSLTVER}-xslt-only.zip"
        schzip, headers = urlretrieve(url)
        if self.bdist_dir:
            self.bdist_dir.mkdir(parents=True, exist_ok=True)
            (self.bdist_dir / "file.txt").write_text("hello world", encoding="utf-8")

        zf = zipfile.ZipFile(schzip)
        for f in zf.namelist():
            if not f.endswith("/") and "2.0" in f:
                zf.extract(f,path=self.bdist_dir)
        output_dir = self.bdist_dir / "vodmltools"
        output_dir.mkdir(parents=True, exist_ok=True)
        if(self.editable_mode):
            os.rename(Path(self.bdist_dir)/f"schxslt-{SCHXSLTVER}/2.0","src/vodmltools/schxslt")
        else:
            os.rename(Path(self.bdist_dir)/f"schxslt-{SCHXSLTVER}/2.0",Path(self.bdist_dir)/"vodmltools/schxslt")


class CustomBuild(build):
    sub_commands = [('build_custom', None)] + build.sub_commands

setup(cmdclass={'build': CustomBuild, 'build_custom': GetSchxslt})
