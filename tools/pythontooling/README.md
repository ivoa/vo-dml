vodmltools
===========

This is a python package for creating and manipulating VO-DML products.

note that because XML Catalogues do not seem to be working properly in python saxon, anything non-trivial is unlikely to work.

## Installation

```shell
pip install vodmltools  --extra-index-url https://repo.dev.uksrc.org/repository/pypi-public/simple
```

For development:
```shell
python -m venv .venv
source .venv/bin/activate
pip install --editable .
```

## Command Reference

The `vodml` CLI aims for parity with the Gradle plugin task surface.

| Gradle Task          | Python CLI Command    | Status          |
|---------------------|-----------------------|-----------------|
| `vodmlDoc`          | `vodml doc`           | ✅ Implemented  |
| `vodmlSite`         | `vodml site`          | ✅ Implemented  |
| `vodmlValidate`     | `vodml validate`      | ✅ Implemented  |
| `vodmlSchema`       | `vodml schema`        | ✅ Implemented  |
| `vodmlJavaGenerate` | `vodml java-generate` | ✅ Implemented  |
| `vodmlPythonGenerate`| `vodml python-generate`| ✅ Implemented |
| `vodmlToVodsl`      | `vodml vodml-to-vodsl`| ✅ Implemented  |
| `vodmlXsdToVodsl`   | `vodml xsd-to-vodsl`  | ✅ Implemented  |
| `vodslToVodml`      | `vodml vodsl-to-vodml`| ⚠️ Requires Java parser |
| `vodmlGenerateJava` | `vodml generate-java` | ✅ Deprecated alias |

### Common Options

Most commands accept:

- `--binding` – comma-separated binding files. Auto-detected from `*vodml-binding.xml` in the current directory if omitted.
- `--deps` – comma-separated dependency VO-DML model files.
- `--output-dir` – output directory (each command has a sensible default under `build/generated/...`).

### Examples

**Generate all schema artefacts (XSD, JSON, OpenAPI YAML, TAP, PlantUML):**
```shell
vodml schema --binding my_binding.vodml-binding.xml \
  --deps IVOA-v1.0.vo-dml.xml \
  my_model.vo-dml.xml
```

**Generate HTML/GraphML/LaTeX documentation:**
```shell
vodml doc --binding my_binding.vodml-binding.xml \
  --deps IVOA-v1.0.vo-dml.xml \
  my_model.vo-dml.xml
```

**Generate mkdocs-suitable site:**
```shell
vodml site --binding my_binding.vodml-binding.xml \
  --deps IVOA-v1.0.vo-dml.xml \
  my_model.vo-dml.xml
```

**Validate a VO-DML model:**
```shell
vodml validate --deps IVOA-v1.0.vo-dml.xml my_model.vo-dml.xml
```

**Convert VO-DML to VODSL:**
```shell
vodml vodml-to-vodsl my_model.vo-dml.xml --output my_model.vodsl
```

**Convert XSD to VODSL:**
```shell
vodml xsd-to-vodsl my_schema.xsd --output my_model.vodsl
```

**Generate Java code:**
```shell
vodml java-generate --binding my_binding.vodml-binding.xml \
  --deps IVOA-v1.0.vo-dml.xml \
  my_model.vo-dml.xml
```

**Generate Python code:**
```shell
vodml python-generate --binding my_binding.vodml-binding.xml \
  --deps IVOA-v1.0.vo-dml.xml \
  my_model.vo-dml.xml
```

### External Tool Prerequisites

Some commands require external tools:

- **graphviz** (`dot`) – required by `doc` and `site` for SVG diagram generation.
- **mkdocs** – required to build the final site from `vodml site` output.
- **plantuml** – can render `.plantuml` files from `vodml schema`.

## Developer Notes

Build with:
```shell
python -m build
```

Note that the XSLT source which lives in a sibling directory `../xslt` to this is included by creating a symbolic link.
The schxslt library for schematron validation is downloaded during the build process via `setup.py`.

On Mac to get a suitable dev env:
```shell
docker run -it --rm -v `pwd`:/vodml:rw --platform linux/amd64 python:3.12-bookworm bash
```

### Links
* https://click.palletsprojects.com/en/stable/
* https://github.com/ivoa/vo-dml/issues/63