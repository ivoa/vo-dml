"""Tests for the vodml CLI command registration and basic option parsing."""

from click.testing import CliRunner

from vodmltools.cli import app


runner = CliRunner()


class TestAppGroup:
    def test_help_shows_all_commands(self):
        result = runner.invoke(app, ["--help"])
        assert result.exit_code == 0
        # Check that all expected commands are listed
        for cmd in [
            "schema",
            "doc",
            "site",
            "validate",
            "vodml-to-vodsl",
            "xsd-to-vodsl",
            "java-generate",
            "python-generate",
            "vodsl-to-vodml",
        ]:
            assert cmd in result.output, f"Command '{cmd}' not found in help output"

    def test_version_option(self):
        result = runner.invoke(app, ["--version"])
        assert result.exit_code == 0


class TestSchemaCommand:
    def test_schema_help(self):
        result = runner.invoke(app, ["schema", "--help"])
        assert result.exit_code == 0
        assert "--binding" in result.output
        assert "--deps" in result.output
        assert "--output-dir" in result.output

    def test_schema_requires_vodmlfile(self):
        result = runner.invoke(app, ["schema"])
        assert result.exit_code != 0


class TestDocCommand:
    def test_doc_help(self):
        result = runner.invoke(app, ["doc", "--help"])
        assert result.exit_code == 0
        assert "--binding" in result.output
        assert "--deps" in result.output
        assert "--models-to-document" in result.output

    def test_doc_requires_vodmlfile(self):
        result = runner.invoke(app, ["doc"])
        assert result.exit_code != 0


class TestSiteCommand:
    def test_site_help(self):
        result = runner.invoke(app, ["site", "--help"])
        assert result.exit_code == 0
        assert "--binding" in result.output


class TestValidateCommand:
    def test_validate_help(self):
        result = runner.invoke(app, ["validate", "--help"])
        assert result.exit_code == 0
        assert "--deps" in result.output


class TestVodmlToVodslCommand:
    def test_help(self):
        result = runner.invoke(app, ["vodml-to-vodsl", "--help"])
        assert result.exit_code == 0
        assert "--output" in result.output


class TestXsdToVodslCommand:
    def test_help(self):
        result = runner.invoke(app, ["xsd-to-vodsl", "--help"])
        assert result.exit_code == 0
        assert "--output" in result.output


class TestJavaGenerateCommand:
    def test_help(self):
        result = runner.invoke(app, ["java-generate", "--help"])
        assert result.exit_code == 0
        assert "--binding" in result.output
        assert "--output-dir" in result.output


class TestPythonGenerateCommand:
    def test_help(self):
        result = runner.invoke(app, ["python-generate", "--help"])
        assert result.exit_code == 0
        assert "--binding" in result.output


class TestVodslToVodmlCommand:
    def test_exits_with_error(self):
        result = runner.invoke(app, ["vodsl-to-vodml", "dummy.vodsl"])
        assert result.exit_code == 1
        assert "Java-based VODSL parser" in result.output


class TestGenerateJavaDeprecated:
    def test_deprecated_alias_exists(self):
        result = runner.invoke(app, ["generate-java", "--help"])
        assert result.exit_code == 0
