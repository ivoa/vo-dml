"""Tests for the vodmltools context module and CLI option parsing."""

import os
import tempfile

import pytest

from vodmltools.context import (
    binding_as_uri_csv,
    detect_binding_files,
    ensure_dir,
    find_vodml_files,
    find_vodsl_files,
    make_catalog,
    resolve_binding,
    resolve_deps,
)


class TestResolveBinding:
    def test_returns_absolute_paths_from_csv(self, tmp_path):
        f1 = tmp_path / "a.vodml-binding.xml"
        f2 = tmp_path / "b.vodml-binding.xml"
        f1.touch()
        f2.touch()
        result = resolve_binding(f"{f1},{f2}", auto_detect=False)
        assert len(result) == 2
        assert all(os.path.isabs(p) for p in result)

    def test_returns_empty_when_none_and_no_autodetect(self):
        result = resolve_binding(None, auto_detect=False)
        assert result == []

    def test_strips_whitespace(self, tmp_path):
        f = tmp_path / "x.xml"
        f.touch()
        result = resolve_binding(f" {f} , ", auto_detect=False)
        assert len(result) == 1

    def test_auto_detect_in_directory(self, tmp_path):
        binding = tmp_path / "model.vodml-binding.xml"
        binding.touch()
        old_cwd = os.getcwd()
        try:
            os.chdir(tmp_path)
            result = resolve_binding(None, auto_detect=True)
            assert len(result) == 1
        finally:
            os.chdir(old_cwd)


class TestResolveDeps:
    def test_returns_empty_for_none(self):
        assert resolve_deps(None) == []

    def test_splits_comma_separated(self):
        assert resolve_deps("a.xml,b.xml") == ["a.xml", "b.xml"]

    def test_strips_whitespace_and_empty(self):
        assert resolve_deps(" a.xml , , b.xml ") == ["a.xml", "b.xml"]


class TestMakeCatalog:
    def test_creates_catalog_file(self, tmp_path):
        vf = tmp_path / "test.vo-dml.xml"
        vf.write_text("<model/>")
        cat = make_catalog([str(vf)], catalog_path=str(tmp_path / "cat.xml"))
        assert os.path.exists(cat)
        content = open(cat).read()
        assert "test.vo-dml.xml" in content
        assert "urn:oasis:names:tc:entity:xmlns:xml:catalog" in content

    def test_includes_deps_in_catalog(self, tmp_path):
        vf = tmp_path / "main.vo-dml.xml"
        dep = tmp_path / "dep.vo-dml.xml"
        vf.write_text("<model/>")
        dep.write_text("<model/>")
        cat = make_catalog([str(vf)], deps=[str(dep)], catalog_path=str(tmp_path / "cat.xml"))
        content = open(cat).read()
        assert "main.vo-dml.xml" in content
        assert "dep.vo-dml.xml" in content

    def test_auto_temp_file_when_no_path(self, tmp_path):
        vf = tmp_path / "test.vo-dml.xml"
        vf.write_text("<model/>")
        cat = make_catalog([str(vf)])
        assert os.path.exists(cat)


class TestEnsureDir:
    def test_creates_nested_dirs(self, tmp_path):
        d = str(tmp_path / "a" / "b" / "c")
        result = ensure_dir(d)
        assert os.path.isdir(result)

    def test_returns_path(self, tmp_path):
        d = str(tmp_path / "out")
        assert ensure_dir(d) == d


class TestFindFiles:
    def test_find_vodml_files(self, tmp_path):
        d = tmp_path / "src" / "main" / "vo-dml"
        d.mkdir(parents=True)
        (d / "test.vo-dml.xml").touch()
        (d / "other.txt").touch()
        result = find_vodml_files(str(d))
        assert len(result) == 1
        assert result[0].endswith("test.vo-dml.xml")

    def test_find_vodml_files_empty_dir(self, tmp_path):
        assert find_vodml_files(str(tmp_path / "nonexistent")) == []

    def test_find_vodsl_files(self, tmp_path):
        d = tmp_path / "src" / "main" / "vodsl"
        d.mkdir(parents=True)
        (d / "model.vodsl").touch()
        result = find_vodsl_files(str(d))
        assert len(result) == 1

    def test_find_vodsl_files_empty(self, tmp_path):
        assert find_vodsl_files(str(tmp_path / "nonexistent")) == []


class TestDetectBindingFiles:
    def test_detects_binding_files(self, tmp_path):
        (tmp_path / "mymodel.vodml-binding.xml").touch()
        (tmp_path / "other.xml").touch()
        result = detect_binding_files(str(tmp_path))
        assert len(result) == 1
        assert result[0].endswith("vodml-binding.xml")

    def test_no_binding_files(self, tmp_path):
        assert detect_binding_files(str(tmp_path)) == []


class TestBindingAsUriCsv:
    def test_produces_file_uris(self, tmp_path):
        f = tmp_path / "binding.xml"
        f.touch()
        csv = binding_as_uri_csv([str(f)])
        assert csv.startswith("file:")
        assert "binding.xml" in csv

    def test_comma_separated(self, tmp_path):
        f1 = tmp_path / "a.xml"
        f2 = tmp_path / "b.xml"
        f1.touch()
        f2.touch()
        csv = binding_as_uri_csv([str(f1), str(f2)])
        assert "," in csv
