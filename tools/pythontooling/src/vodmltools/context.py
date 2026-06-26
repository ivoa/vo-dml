"""Shared execution context for VO-DML CLI commands.

Centralises file discovery, catalog creation, binding detection,
and output directory management so that all CLI commands share
identical behavior - mirroring the Gradle plugin defaults from
VodmlExtension.kt.
"""

import glob
import os
import tempfile
from pathlib import Path, PurePath

from vodmltools.vodml import createCatalog


# Default directory conventions matching VodmlExtension.kt
DEFAULT_VODML_DIR = os.path.join("src", "main", "vo-dml")
DEFAULT_VODSL_DIR = os.path.join("src", "main", "vodsl")
DEFAULT_OUTPUT_DOC_DIR = os.path.join("build", "generated", "docs", "vodml")
DEFAULT_OUTPUT_SITE_DIR = os.path.join("build", "generated", "docs", "vodml-site")
DEFAULT_OUTPUT_SCHEMA_DIR = os.path.join("build", "generated", "sources", "vodml", "schema")
DEFAULT_OUTPUT_JAVA_DIR = os.path.join("build", "generated", "sources", "vodml", "java")
DEFAULT_OUTPUT_PYTHON_DIR = os.path.join("build", "generated", "sources", "vodml", "python")


def find_vodml_files(vodml_dir=None):
    """Discover *.vo-dml.xml files in the given directory (or default)."""
    d = vodml_dir or DEFAULT_VODML_DIR
    if not os.path.isdir(d):
        return []
    return sorted(glob.glob(os.path.join(d, "**", "*.vo-dml.xml"), recursive=True))


def find_vodsl_files(vodsl_dir=None):
    """Discover *.vodsl files in the given directory (or default)."""
    d = vodsl_dir or DEFAULT_VODSL_DIR
    if not os.path.isdir(d):
        return []
    return sorted(glob.glob(os.path.join(d, "**", "*.vodsl"), recursive=True))


def detect_binding_files(project_dir=None):
    """Auto-detect ``*vodml-binding.xml`` files in the project root directory."""
    d = project_dir or "."
    return sorted(glob.glob(os.path.join(d, "*vodml-binding.xml")))


def ensure_dir(path):
    """Create a directory (and parents) if it does not exist, return the path."""
    os.makedirs(path, exist_ok=True)
    return path


def make_catalog(vodml_files, catalog_path=None, deps=None):
    """Build an XML catalog covering *vodml_files* and optional *deps*.

    Parameters
    ----------
    vodml_files : list[str]
        Primary VO-DML files.
    catalog_path : str or None
        Where to write the catalog.  When ``None`` a temp file is used.
    deps : list[str] or None
        Additional dependency model files to include.

    Returns
    -------
    str
        Absolute path of the catalog file.
    """
    all_files = list(vodml_files)
    if deps:
        all_files.extend(deps)
    if catalog_path is None:
        fd, catalog_path = tempfile.mkstemp(suffix=".xml", prefix="vodml-catalog-")
        os.close(fd)
    createCatalog(catalog_path, all_files)
    return os.path.abspath(catalog_path)


def resolve_binding(binding_arg, auto_detect=True):
    """Normalise a binding argument into a list of absolute paths.

    Parameters
    ----------
    binding_arg : str or None
        Comma-separated binding file paths from CLI, or ``None``.
    auto_detect : bool
        When *binding_arg* is ``None`` and *auto_detect* is ``True``,
        try ``detect_binding_files()``.

    Returns
    -------
    list[str]
        List of absolute paths to binding files.
    """
    if binding_arg:
        return [os.path.abspath(b.strip()) for b in binding_arg.split(",") if b.strip()]
    if auto_detect:
        return [os.path.abspath(b) for b in detect_binding_files()]
    return []


def binding_as_uri_csv(binding_files):
    """Convert a list of binding file paths to a comma-separated URI string
    suitable for passing as an XSLT parameter (matches Gradle behaviour)."""
    return ",".join(PurePath(os.path.abspath(b)).as_uri() for b in binding_files)


def resolve_deps(deps_arg):
    """Normalise a deps argument into a list of paths.

    Parameters
    ----------
    deps_arg : str or None
        Comma-separated dependency model paths from CLI.

    Returns
    -------
    list[str]
    """
    if not deps_arg:
        return []
    return [d.strip() for d in deps_arg.split(",") if d.strip()]


def prepare_transform(transformer, vodml_files, deps=None, catalog_path=None):
    """Set up the catalog on *transformer* and return the catalog path.

    This is the common pattern used by most commands:
    create catalog → set on transformer → return path.
    """
    cat = make_catalog(vodml_files, catalog_path=catalog_path, deps=deps)
    transformer.setCatalog(cat)
    return cat
