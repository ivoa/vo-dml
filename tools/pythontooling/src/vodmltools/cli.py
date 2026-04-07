import json
import os
import subprocess
import sys

import click

from vodmltools.vodml import (
    Vodml2Gml,
    Vodml2Gvd,
    Vodml2Html,
    Vodml2Java,
    Vodml2Latex,
    Vodml2Python,
    Vodml2TAP,
    Vodml2Vodsl,
    Vodml2json,
    Vodml2md,
    Vodml2xsdNew,
    TapSchema2PlantUML,
    Vodml2Catalogues,
    Xsd2Vodsl,
    createCatalog,
)
from vodmltools.context import (
    binding_as_uri_csv,
    ensure_dir,
    make_catalog,
    prepare_transform,
    resolve_binding,
    resolve_deps,
    DEFAULT_OUTPUT_DOC_DIR,
    DEFAULT_OUTPUT_JAVA_DIR,
    DEFAULT_OUTPUT_PYTHON_DIR,
    DEFAULT_OUTPUT_SCHEMA_DIR,
    DEFAULT_OUTPUT_SITE_DIR,
)


@click.group()
@click.version_option()
def app():
    """toolkit for manipulating VO-DML"""


# ---------------------------------------------------------------------------
# Common option helpers
# ---------------------------------------------------------------------------

_binding_option = click.option(
    "--binding", type=str, default=None,
    help="Comma-separated binding files (auto-detected if omitted).",
)
_deps_option = click.option(
    "--deps", type=str, default=None,
    help="Comma-separated list of dependency VO-DML model files.",
)
_output_option = click.option(
    "--output-dir", "output_dir", type=click.Path(), default=None,
    help="Output directory (defaults vary per command).",
)


# ---------------------------------------------------------------------------
# schema
# ---------------------------------------------------------------------------

@app.command("schema")
@_binding_option
@_deps_option
@_output_option
@click.argument("vodmlfiles", nargs=-1, required=True)
def schema(binding, deps, output_dir, vodmlfiles):
    """Generate schema artefacts (XSD, JSON, TAP, PlantUML) from VO-DML files."""
    vodmlfiles = list(vodmlfiles)
    outdir = ensure_dir(output_dir or DEFAULT_OUTPUT_SCHEMA_DIR)
    dep_list = resolve_deps(deps)
    binding_files = resolve_binding(binding)
    binding_csv = binding_as_uri_csv(binding_files) if binding_files else ""

    cat = make_catalog(vodmlfiles, deps=dep_list)

    click.echo(f"Generating schema artefacts for {', '.join(vodmlfiles)}")

    for vf in vodmlfiles:
        shortname = os.path.splitext(os.path.splitext(os.path.basename(vf))[0])[0]

        # XSD
        click.echo(f"  XSD: {shortname}.xsd")
        Vodml2xsdNew.setCatalog(cat)
        params = {"binding": binding_csv} if binding_csv else {}
        Vodml2xsdNew.doTransform(vf, params, os.path.join(outdir, f"{shortname}.xsd"))

        # JSON schema (pretty-printed)
        click.echo(f"  JSON: {shortname}.json")
        Vodml2json.setCatalog(cat)
        raw = Vodml2json.doTransformToString(vf, {"binding": binding_csv} if binding_csv else {})
        if raw:
            try:
                parsed = json.loads(raw)
                pretty = json.dumps(parsed, indent=2)
            except json.JSONDecodeError:
                pretty = raw
            with open(os.path.join(outdir, f"{shortname}.json"), "w") as f:
                f.write(pretty)

        # OpenAPI YAML
        click.echo(f"  OpenAPI: {shortname}.yaml")
        raw_api = Vodml2json.doTransformToString(
            vf, {"binding": binding_csv, "jsonmode": "openapi"} if binding_csv else {"jsonmode": "openapi"},
        )
        if raw_api:
            try:
                import yaml  # noqa: F811

                parsed_api = json.loads(raw_api)
                _remove_key_recursively(parsed_api, "$comment")
                yaml_str = yaml.dump(parsed_api, default_flow_style=False, sort_keys=False)
            except (json.JSONDecodeError, ImportError):
                yaml_str = raw_api
            with open(os.path.join(outdir, f"{shortname}.yaml"), "w") as f:
                f.write(yaml_str)

        # TAP schema
        click.echo(f"  TAP: {shortname}.tap.xml")
        Vodml2TAP.setCatalog(cat)
        Vodml2TAP.doTransform(vf, {"binding": binding_csv} if binding_csv else {}, os.path.join(outdir, f"{shortname}.tap.xml"))

        # TAP PlantUML
        click.echo(f"  TAP PlantUML: {shortname}.tap.plantuml")
        TapSchema2PlantUML.setCatalog(cat)
        TapSchema2PlantUML.doTransform(
            os.path.join(outdir, f"{shortname}.tap.xml"),
            {"binding": binding_csv} if binding_csv else {},
            os.path.join(outdir, f"{shortname}.tap.plantuml"),
        )

    # Catalogues
    click.echo("  Generating catalogues")
    try:
        xmlcat_path = os.path.join(outdir, "xmlcat.xml")
        jsoncat_path = os.path.join(outdir, "jsoncat.txt")
        Vodml2Catalogues.setCatalog(cat)
        Vodml2Catalogues.doTransform({
            "binding": binding_csv,
            "xml-catalogue": _path_to_uri(xmlcat_path),
            "json-catalogue": _path_to_uri(jsoncat_path),
        })
    except Exception as e:  # noqa: BLE001
        click.echo(f"  Warning: catalogue generation failed: {e}", err=True)


# ---------------------------------------------------------------------------
# doc
# ---------------------------------------------------------------------------

@app.command("doc")
@_binding_option
@_deps_option
@_output_option
@click.option("--models-to-document", type=str, default=None, help="Restrict which models to document.")
@click.argument("vodmlfiles", nargs=-1, required=True)
def doc(binding, deps, output_dir, models_to_document, vodmlfiles):
    """Generate documentation (GVD, SVG, HTML, GraphML, LaTeX) from VO-DML files."""
    vodmlfiles = list(vodmlfiles)
    outdir = ensure_dir(output_dir or DEFAULT_OUTPUT_DOC_DIR)
    dep_list = resolve_deps(deps)
    cat = make_catalog(vodmlfiles, deps=dep_list)

    click.echo(f"Generating documentation for {', '.join(vodmlfiles)}")

    for vf in vodmlfiles:
        shortname = os.path.splitext(os.path.splitext(os.path.basename(vf))[0])[0]

        # GVD (Graphviz dot source)
        gvd_path = os.path.join(outdir, f"{shortname}.gvd")
        click.echo(f"  GVD: {shortname}.gvd")
        Vodml2Gvd.setCatalog(cat)
        Vodml2Gvd.doTransform(vf, {}, gvd_path)

        # dot → SVG
        svg_path = os.path.join(outdir, f"{shortname}.svg")
        click.echo(f"  SVG: {shortname}.svg")
        try:
            proc = subprocess.run(
                ["dot", "-Tsvg", f"-o{svg_path}", gvd_path],
                cwd=outdir, capture_output=True, text=True, timeout=30,
            )
            if proc.returncode != 0:
                click.echo(f"  Warning: dot failed: {proc.stderr}", err=True)
        except FileNotFoundError:
            click.echo("  Warning: 'dot' (graphviz) not found – SVG not generated.", err=True)

        # HTML
        html_path = os.path.join(outdir, f"{shortname}.html")
        click.echo(f"  HTML: {shortname}.html")
        Vodml2Html.setCatalog(cat)
        Vodml2Html.doTransform(vf, {"graphviz_png": os.path.abspath(svg_path)}, html_path)

        # GraphML
        graphml_path = os.path.join(outdir, f"{shortname}.graphml")
        click.echo(f"  GraphML: {shortname}.graphml")
        Vodml2Gml.setCatalog(cat)
        Vodml2Gml.doTransform(vf, {}, graphml_path)

        # LaTeX
        tex_path = os.path.join(outdir, f"{shortname}_desc.tex")
        click.echo(f"  LaTeX: {shortname}_desc.tex")
        params = {}
        if models_to_document:
            params["modelsToDocument"] = models_to_document
        Vodml2Latex.setCatalog(cat)
        Vodml2Latex.doTransform(vf, params, tex_path)


# ---------------------------------------------------------------------------
# site
# ---------------------------------------------------------------------------

@app.command("site")
@_binding_option
@_deps_option
@_output_option
@click.option("--models-to-document", type=str, default=None, help="Restrict which models to document.")
@click.argument("vodmlfiles", nargs=-1, required=True)
def site(binding, deps, output_dir, models_to_document, vodmlfiles):
    """Generate mkdocs-suitable site documentation from VO-DML files."""
    vodmlfiles = list(vodmlfiles)
    outdir = ensure_dir(output_dir or DEFAULT_OUTPUT_SITE_DIR)
    dep_list = resolve_deps(deps)
    binding_files = resolve_binding(binding)
    binding_csv = binding_as_uri_csv(binding_files) if binding_files else ""
    cat = make_catalog(vodmlfiles, deps=dep_list)

    click.echo(f"Generating site for {', '.join(vodmlfiles)}")

    all_vodml = list(vodmlfiles) + dep_list

    for vf in all_vodml:
        shortname = os.path.splitext(os.path.splitext(os.path.basename(vf))[0])[0]

        # GVD with linkmode=md
        gvd_path = os.path.join(outdir, f"{shortname}.gvd")
        click.echo(f"  GVD: {shortname}.gvd")
        Vodml2Gvd.setCatalog(cat)
        Vodml2Gvd.doTransform(vf, {"linkmode": "md"}, gvd_path)

        # dot → SVG
        svg_path = os.path.join(outdir, f"{shortname}.svg")
        click.echo(f"  SVG: {shortname}.svg")
        try:
            proc = subprocess.run(
                ["dot", "-Tsvg", f"-o{svg_path}", gvd_path],
                cwd=outdir, capture_output=True, text=True, timeout=30,
            )
            if proc.returncode != 0:
                click.echo(f"  Warning: dot failed: {proc.stderr}", err=True)
        except FileNotFoundError:
            click.echo("  Warning: 'dot' (graphviz) not found – SVG not generated.", err=True)

        # Markdown
        md_path = os.path.join(outdir, f"{shortname}.md")
        click.echo(f"  MD: {shortname}.md")
        params = {
            "graphviz_png": os.path.abspath(svg_path),
        }
        if binding_csv:
            params["binding"] = binding_csv
        if models_to_document:
            params["modelsToDocument"] = models_to_document
        Vodml2md.setCatalog(cat)
        Vodml2md.doTransform(vf, params, md_path)

        # GraphML
        graphml_path = os.path.join(outdir, f"{shortname}.graphml")
        click.echo(f"  GraphML: {shortname}.graphml")
        Vodml2Gml.setCatalog(cat)
        Vodml2Gml.doTransform(vf, {}, graphml_path)

    # Nav aggregation
    click.echo("  Aggregating navigation")
    try:
        allnav = []
        for vf in vodmlfiles:
            shortname = os.path.splitext(os.path.splitext(os.path.basename(vf))[0])[0]
            nav_file = os.path.join(outdir, f"{shortname}_nav.json")
            if os.path.exists(nav_file):
                with open(nav_file) as f:
                    allnav.append(json.load(f))

        imported_models = []
        for dep_file in dep_list:
            shortname = os.path.splitext(os.path.splitext(os.path.basename(dep_file))[0])[0]
            nav_file = os.path.join(outdir, f"{shortname}_nav.json")
            if os.path.exists(nav_file):
                with open(nav_file) as f:
                    imported_models.append(json.load(f))

        if imported_models:
            allnav.append({"Imported Models": imported_models})

        try:
            import yaml

            allnav_path = os.path.join(outdir, "allnav.yml")
            with open(allnav_path, "w") as f:
                yaml.dump(allnav, f, default_flow_style=False, sort_keys=False)
        except ImportError:
            allnav_path = os.path.join(outdir, "allnav.json")
            with open(allnav_path, "w") as f:
                json.dump(allnav, f, indent=2)
    except Exception as e:  # noqa: BLE001
        click.echo(f"  Warning: nav aggregation failed: {e}", err=True)


# ---------------------------------------------------------------------------
# validate
# ---------------------------------------------------------------------------

@app.command("validate")
@_deps_option
@click.argument("vodmlfiles", nargs=-1, required=True)
def validate(deps, vodmlfiles):
    """Validate VO-DML files with schematron rules.

    Exits with non-zero status when validation fails.
    """
    from vodmltools.schematron import Schematron

    vodmlfiles = list(vodmlfiles)
    dep_list = resolve_deps(deps)
    cat = make_catalog(vodmlfiles, deps=dep_list)

    click.echo(f"Validating {', '.join(vodmlfiles)}")

    has_errors = False
    for vf in vodmlfiles:
        shortname = os.path.splitext(os.path.splitext(os.path.basename(vf))[0])[0]
        click.echo(f"  Validating {shortname}...")

        try:
            sch = Schematron()
            sch.validate(vf)
        except Exception as e:  # noqa: BLE001
            click.echo(f"  ERROR validating {shortname}: {e}", err=True)
            has_errors = True

    if has_errors:
        raise SystemExit(1)


# ---------------------------------------------------------------------------
# vodml-to-vodsl
# ---------------------------------------------------------------------------

@app.command("vodml-to-vodsl")
@click.argument("vodmlfile")
@click.option("--output", "output_file", type=click.Path(), default=None,
              help="Output VODSL file (defaults to <basename>.vodsl).")
def vodml_to_vodsl(vodmlfile, output_file):
    """Convert a VO-DML file to VODSL."""
    if output_file is None:
        base = os.path.splitext(os.path.splitext(os.path.basename(vodmlfile))[0])[0]
        output_file = f"{base}.vodsl"

    click.echo(f"Converting {vodmlfile} → {output_file}")
    cat = make_catalog([vodmlfile])
    Vodml2Vodsl.setCatalog(cat)
    Vodml2Vodsl.doTransform(vodmlfile, {}, output_file)
    click.echo(f"  Written: {output_file}")


# ---------------------------------------------------------------------------
# xsd-to-vodsl
# ---------------------------------------------------------------------------

@app.command("xsd-to-vodsl")
@click.argument("xsdfile")
@click.option("--output", "output_file", type=click.Path(), default=None,
              help="Output VODSL file (defaults to <basename>.vodsl).")
def xsd_to_vodsl(xsdfile, output_file):
    """Convert an XML Schema (XSD) file to VODSL."""
    if output_file is None:
        base = os.path.splitext(os.path.basename(xsdfile))[0]
        output_file = f"{base}.vodsl"

    click.echo(f"Converting {xsdfile} → {output_file}")
    cat = make_catalog([xsdfile])
    Xsd2Vodsl.setCatalog(cat)
    Xsd2Vodsl.doTransform(xsdfile, {}, output_file)
    click.echo(f"  Written: {output_file}")


# ---------------------------------------------------------------------------
# java-generate  (+ deprecated alias generate-java)
# ---------------------------------------------------------------------------

@app.command("java-generate")
@_binding_option
@_deps_option
@_output_option
@click.argument("vodmlfiles", nargs=-1, required=True)
def java_generate(binding, deps, output_dir, vodmlfiles):
    """Generate Java classes from VO-DML models."""
    vodmlfiles = list(vodmlfiles)
    outdir = ensure_dir(output_dir or DEFAULT_OUTPUT_JAVA_DIR)
    dep_list = resolve_deps(deps)
    binding_files = resolve_binding(binding)
    binding_csv = binding_as_uri_csv(binding_files) if binding_files else ""
    cat = make_catalog(vodmlfiles, deps=dep_list)

    click.echo(f"Generating Java for {', '.join(vodmlfiles)}")
    pu_name = os.path.splitext(os.path.splitext(os.path.basename(vodmlfiles[0]))[0])[0]

    for index, vf in enumerate(vodmlfiles):
        shortname = os.path.splitext(os.path.splitext(os.path.basename(vf))[0])[0]
        outfile = os.path.join(outdir, f"{shortname}.javatrans.txt")
        click.echo(f"  {shortname} → {outfile}")
        Vodml2Java.setCatalog(cat)
        params = {
            "output_root": _path_to_uri(outdir) + "/",
            "isMain": "True" if index == 0 else "False",
            "pu_name": pu_name,
        }
        if binding_csv:
            params["binding"] = binding_csv
        Vodml2Java.doTransform(vf, params, outfile)


# deprecated alias
@app.command("generate-java", hidden=True)
@_binding_option
@_deps_option
@_output_option
@click.argument("vodmlfiles", nargs=-1, required=True)
@click.pass_context
def generate_java(ctx, binding, deps, output_dir, vodmlfiles):
    """(Deprecated) Alias for java-generate."""
    click.echo("Warning: 'generate-java' is deprecated, use 'java-generate' instead.", err=True)
    ctx.invoke(java_generate, binding=binding, deps=deps, output_dir=output_dir, vodmlfiles=vodmlfiles)


# ---------------------------------------------------------------------------
# python-generate
# ---------------------------------------------------------------------------

@app.command("python-generate")
@_binding_option
@_deps_option
@_output_option
@click.argument("vodmlfiles", nargs=-1, required=True)
def python_generate(binding, deps, output_dir, vodmlfiles):
    """Generate Python classes from VO-DML models."""
    vodmlfiles = list(vodmlfiles)
    outdir = ensure_dir(output_dir or DEFAULT_OUTPUT_PYTHON_DIR)
    dep_list = resolve_deps(deps)
    binding_files = resolve_binding(binding)
    binding_csv = binding_as_uri_csv(binding_files) if binding_files else ""
    cat = make_catalog(vodmlfiles, deps=dep_list)

    click.echo(f"Generating Python for {', '.join(vodmlfiles)}")

    for index, vf in enumerate(vodmlfiles):
        shortname = os.path.splitext(os.path.splitext(os.path.basename(vf))[0])[0]
        outfile = os.path.join(outdir, f"{shortname}.pythontrans.txt")
        click.echo(f"  {shortname} → {outfile}")
        Vodml2Python.setCatalog(cat)
        params = {
            "output_root": _path_to_uri(outdir) + "/",
            "isMain": "True" if index == 0 else "False",
        }
        if binding_csv:
            params["binding"] = binding_csv
        Vodml2Python.doTransform(vf, params, outfile)


# ---------------------------------------------------------------------------
# vodsl-to-vodml
# ---------------------------------------------------------------------------

@app.command("vodsl-to-vodml")
@click.argument("vodslfiles", nargs=-1, required=True)
@click.option("--output-dir", "output_dir", type=click.Path(), default=None,
              help="Output directory for VO-DML files (default: src/main/vo-dml).")
def vodsl_to_vodml(vodslfiles, output_dir):
    """Convert VODSL files to VO-DML.

    Note: this command requires the VODSL parser (Java). It is not yet
    available in the Python tooling. Use the Gradle task ``vodslToVodml``
    instead.
    """
    click.echo(
        "Error: vodsl-to-vodml requires the Java-based VODSL parser which "
        "is not available in the Python tooling.\n"
        "Use the Gradle task instead:  ./gradlew vodslToVodml",
        err=True,
    )
    raise SystemExit(1)


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

def _path_to_uri(path):
    """Convert a local file path to a file:// URI."""
    return PurePath(os.path.abspath(path)).as_uri()


def _remove_key_recursively(obj, key_to_remove):
    """Remove *key_to_remove* from a nested dict/list structure in-place."""
    if isinstance(obj, dict):
        keys = list(obj.keys())
        for k in keys:
            if k == key_to_remove:
                del obj[k]
            else:
                _remove_key_recursively(obj[k], key_to_remove)
    elif isinstance(obj, list):
        for item in obj:
            _remove_key_recursively(item, key_to_remove)
