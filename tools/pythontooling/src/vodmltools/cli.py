import os
import click
from vodmltools.vodml import *



@click.group()
@click.version_option()
def app():
    """toolkit for manipulating VO-DML"""

@app.command("schema")
@click.option("--binding",type=str, help="binding files")
@click.option("--deps",type=str, help="location dependent models")# TODO decide if deps is bettter repeatable.
@click.argument("vodmlfile")
def schema(binding,vodmlfile, deps ):
    """generates schema from the VODML

    VODML - the VO-DML file definition"""
    click.echo(f'generating schema for {vodmlfile}')
    tmpcat = "tmpcat.xml"
    createCatalog(tmpcat,[vodmlfile] +deps.split(","))
    Vodml2TAP.setCatalog(tmpcat)
    fullpathbinding =",".join( os.path.abspath(v) for v in binding.split(","))
    Vodml2TAP.doTransform(vodmlfile,{"binding":fullpathbinding},"out.xml")

@app.command("doc")
@click.option("--binding",type=str, help="binding file.")
@click.argument("vodmlfile")
def doc(vodmlfile, binding):
    """generates doc from the VODML

    VODML - the VO-DML file definition"""
    click.echo(f'generating doc for {vodmlfile}')



