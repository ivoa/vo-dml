"""
Pydantic interoperability tests.

These tests create the same model instances that the Java serialisation tests produce,
re-serialise them to XML and JSON using the generated pydantic-xml models, and write
the results to interoperability/python/.  The output can then be compared with the
files in interoperability/java/ to evaluate how close the two serialisations are.
"""

import json
import os
import unittest
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

from lxml import etree as _etree

from org.ivoa.dm.filter.filter import PhotometricSystem, PhotometryFilter
from org.ivoa.dm.ivoa import RealQuantity, Unit, anyURI
from org.ivoa.dm.lifecycle.lifecycleTest import LifecycleTestModel, LifecycleTestRefs
from org.ivoa.dm.samplemodel.sample import SampleModel, SampleRefs
from org.ivoa.dm.samplemodel.sample_catalog import (
    AlignedEllipse,
    LuminosityMeasurement,
    LuminosityType,
    SDSSSource,
    SkyCoordinate,
    SkyCoordinateFrame,
    SourceClassification,
)
from org.ivoa.dm.samplemodel.sample_catalog_inner import SourceCatalogue
from org.ivoa.dm.serializationsample.MyModel import MyModelRefs

# Output directory (relative to the sample project root).
_SAMPLE_DIR = Path(__file__).parent.parent.parent
_INTEROP_DIR = _SAMPLE_DIR / "interoperability" / "python"

# Directory containing the generated XSD schemas (populated by :sample:vodmlSchema).
_SCHEMA_DIR = _SAMPLE_DIR / "docs" / "schema"

# The IVOA base XSD lives in the ivoa model build resources (present after :ivoa:jar).
_IVOA_XSD = _SAMPLE_DIR.parent.parent.parent / "models" / "ivoa" / "build" / "resources" / "main" / "IVOA-v1.0.vo-dml.xsd"


class _LocalSchemaResolver(_etree.Resolver):
    """Resolve relative schema imports from ``_SCHEMA_DIR`` or the ivoa build output."""

    def resolve(self, url: str, id, context):
        name = Path(url).name
        local = _SCHEMA_DIR / name
        if local.exists():
            return self.resolve_filename(str(local), context)
        if name == "IVOA-v1.0.vo-dml.xsd" and _IVOA_XSD.exists():
            return self.resolve_filename(str(_IVOA_XSD), context)
        return None


def _load_schema(xsd_name: str) -> "_etree.XMLSchema | None":
    """Load an XMLSchema from *_SCHEMA_DIR*, returning ``None`` when unavailable."""
    xsd_path = _SCHEMA_DIR / xsd_name
    if not xsd_path.exists():
        return None
    parser = _etree.XMLParser()
    parser.resolvers.add(_LocalSchemaResolver())
    return _etree.XMLSchema(_etree.parse(str(xsd_path), parser))


def _validate_xml(xml_bytes: bytes, xsd_name: str, test_case: unittest.TestCase) -> None:
    """Assert that *xml_bytes* validates against the named XSD schema.

    If the schema file is not present (e.g. ``vodmlSchema`` was not run), the
    check is silently skipped so the test does not fail in minimal build
    environments.
    """
    schema = _load_schema(xsd_name)
    if schema is None:
        return
    doc = _etree.fromstring(xml_bytes)
    result = schema.validate(doc)
    if not result:
        errors = "\n".join(str(e) for e in schema.error_log)
        test_case.fail(f"XML failed schema validation against {xsd_name}:\n{errors}")


def _write(filename: str, content: str | bytes) -> None:
    """Write *content* to interoperability/python/<filename>."""
    _INTEROP_DIR.mkdir(parents=True, exist_ok=True)
    dest = _INTEROP_DIR / filename
    if isinstance(content, bytes):
        dest.write_bytes(content)
    else:
        dest.write_text(content, encoding="utf-8")


class SampleModelInteropTest(unittest.TestCase):
    """
    Tests for the Sample model (SourceCatalogue / SDSSSource).

    Mirrors the Java BaseSourceCatalogueTest / SourceCatalogueTest which produce
    interoperability/java/sample.xml  and  interoperability/java/sample.json.
    """

    @classmethod
    def setUpClass(cls):
        jansky = Unit(value="Jy")
        degree = Unit(value="degree")
        ghz = Unit(value="GHz")

        frame = SkyCoordinateFrame(
            name="J2000",
            equinox="J2000.0",
            documentURI=anyURI(value="http://coord.net"),
        )

        c_band = PhotometryFilter(
            name="C-Band",
            description="radio band",
            bandName="C-Band",
            dataValidityFrom=datetime(2020, 1, 1, tzinfo=timezone.utc),
            dataValidityTo=datetime(2025, 1, 1, 20, 12, 16, tzinfo=timezone.utc),
            spectralLocation=RealQuantity(value=5.0, unit=ghz),
        )
        l_band = PhotometryFilter(
            name="L-Band",
            description="radio band",
            bandName="L-Band",
            dataValidityFrom=datetime(2020, 1, 1, tzinfo=timezone.utc),
            dataValidityTo=datetime(2025, 1, 1, 13, 12, 0, tzinfo=timezone.utc),
            spectralLocation=RealQuantity(value=1.5, unit=ghz),
        )

        cls.ps = PhotometricSystem(
            description="test photometric system",
            detectorType=1,
            photometryFilter=[c_band, l_band],
        )

        source = SDSSSource(
            name="testSource",
            label="cepheid",
            classification=SourceClassification.AGN,
            position=SkyCoordinate(
                longitude=RealQuantity(value=2.5, unit=degree),
                latitude=RealQuantity(value=52.5, unit=degree),
                frame=frame,
            ),
            positionError=AlignedEllipse(longError=0.2, latError=0.1),
            luminosity=[
                LuminosityMeasurement(
                    description="lummeas",
                    type=LuminosityType.FLUX,
                    value=RealQuantity(value=2.5, unit=jansky),
                    error=RealQuantity(value=0.25, unit=jansky),
                    filter=c_band,
                ),
                LuminosityMeasurement(
                    description="lummeas2",
                    type=LuminosityType.FLUX,
                    value=RealQuantity(value=3.5, unit=jansky),
                    error=RealQuantity(value=0.25, unit=jansky),
                    filter=l_band,
                ),
            ],
        )

        cls.sc = SourceCatalogue(name="testCat", entry=[source])

        cls.model = SampleModel(photometricSystem=[cls.ps], sourceCatalogue=[cls.sc],refs=SampleRefs(skyCoordinateFrame=[frame]))

    # ------------------------------------------------------------------
    # JSON
    # ------------------------------------------------------------------

    def test_json_serialise(self):
        """Serialise the SourceCatalogue to JSON and write to interoperability/python/."""

        content = json.dumps(self.model, indent=2)
        _write("sample.json", content)
        # Basic structural checks
        data = json.loads(content)
        self.assertEqual(data["sourceCatalogue"]["name"], "testCat")
        entry = data["sourceCatalogue"]["entry"][0]
        self.assertEqual(entry["name"], "testSource")
        self.assertEqual(len(entry["luminosity"]), 2)
        self.assertAlmostEqual(entry["position"]["longitude"]["value"], 2.5)

    def test_json_round_trip(self):
        """Verify that the JSON output can be read back by pydantic."""
        json_str = self.model.model_dump_json()
        recovered = SourceCatalogue.model_validate_json(json_str)
        self.assertEqual(recovered.name, self.sc.name)
        self.assertEqual(len(recovered.entry), 1)

    # ------------------------------------------------------------------
    # XML
    # ------------------------------------------------------------------

    def test_xml_serialise(self):
        """Serialise the SourceCatalogue to XML and write to interoperability/python/."""
        xml_bytes = self.model.to_xml(pretty_print=True)
        _write("sample.xml", xml_bytes)
        _validate_xml(xml_bytes, "Sample.vo-dml.xsd", self)
        # Basic check: output is non-empty XML
        self.assertIn(b"<SourceCatalogue", xml_bytes)
        self.assertIn(b"testCat", xml_bytes)
        self.assertIn(b"testSource", xml_bytes)

    def test_xml_round_trip(self):
        """Verify that the XML output can be read back by pydantic-xml."""
        xml_bytes = self.model.to_xml(pretty_print=True)
        recovered = SourceCatalogue.from_xml(xml_bytes)
        self.assertEqual(recovered.name, self.sc.name)
        self.assertEqual(len(recovered.entry), 1)


class LifecycleModelInteropTest(unittest.TestCase):
    """
    Tests for the Lifecycle test model.

    Mirrors the Java LifecycleTestModelTest which produces
    interoperability/java/lifecycle.xml  and  interoperability/java/lifecycle.json.
    """

    @classmethod
    def setUpClass(cls):
        from org.ivoa.dm.lifecycle.lifecycleTest import (
            ATest,
            ATest2,
            ATest4,
            Contained,
            ReferredLifeCycle,
            ReferredTo,
        )

        ref1 = ReferredTo(test1=3)
        rc1 = ReferredLifeCycle(test3="rc1")
        rc2 = ReferredLifeCycle(test3="rc2")
        contained_obj = ATest4(lowr=rc1)
        atest = ATest(
            ref1=ref1,
            contained=[
                Contained(test2="firstcontained"),
                Contained(test2="secondContained"),
            ],
            refandcontained=[rc1, rc2],
            contained2=contained_obj,
        )
        top = ATest2(atest=atest, refcont=rc1, refagg=[ref1])
        cls.model=LifecycleTestModel(aTest2=[top],refs=LifecycleTestRefs(referredTo=[ref1,rc1, rc2]))

    def test_json_serialise(self):
        json_str = self.model.model_dump_json(indent=2)
        _write("lifecycle.json", json_str)
        data = json.loads(json_str)
        self.assertIn("atest", data)
        self.assertEqual(len(data["atest"]["contained"]), 2)

    def test_json_round_trip(self):
        from org.ivoa.dm.lifecycle.lifecycleTest import ATest2
        json_str = self.model.model_dump_json()
        recovered = ATest2.model_validate_json(json_str)
        self.assertEqual(len(recovered.atest.contained), 2)

    def test_xml_serialise(self):
        xml_bytes = self.model.to_xml(pretty_print=True)
        _write("lifecycle.xml", xml_bytes)
        _validate_xml(xml_bytes, "lifecycleTest.vo-dml.xsd", self)
        self.assertIn(b"<ATest2", xml_bytes)
        self.assertIn(b"firstcontained", xml_bytes)

    def test_xml_round_trip(self):
        from org.ivoa.dm.lifecycle.lifecycleTest import ATest2
        xml_bytes = self.model.to_xml(pretty_print=True)
        recovered = ATest2.from_xml(xml_bytes)
        self.assertEqual(len(recovered.atest.contained), 2)


class SerializationExampleInteropTest(unittest.TestCase):
    """
    Tests for the serialisation example model (MyModel).

    Mirrors the Java SerializationExampleTest which produces
    interoperability/java/serializationsample.xml  and
    interoperability/java/serializationsample.json.
    """

    @classmethod
    def setUpClass(cls):
        from org.ivoa.dm.serializationsample.MyModel import (
            Refa,
            Refb,
            SomeContent,
            altURL,
            ivoid,
            MyModelModel
        )
        from org.ivoa.dm.serializationsample.MyModel_types import BaseC, Dcont, Econt

        refa = Refa(val=altURL(value=anyURI(value="urn:value")))
        refb = Refb(
            name="naturalkey",
            val=ivoid(value=anyURI(value="ivo:val")),
        )
        content = SomeContent(
            ref1=refa,
            ref2=refb,
            zval=["some", "z", "values"],
            con=[
                Dcont(bname="dval", dval="N1"),
                Econt(bname="eval", evalue="cube"),
            ],
        )
        # this now actually matches the java structure
        model = MyModelModel(someContent=[content],refs=MyModelRefs(refa=[refa], refb=[refb]))

        cls.model = model

    def test_json_serialise(self):
        json_str = self.model.model_dump_json(indent=2)
        _write("serializationsample.json", json_str)
        data = json.loads(json_str)
        self.assertEqual(data["zval"], ["some", "z", "values"])
        self.assertEqual(len(data["con"]), 2)

    def test_json_round_trip(self):
        from org.ivoa.dm.serializationsample.MyModel import SomeContent
        json_str = self.model.model_dump_json()
        recovered = SomeContent.model_validate_json(json_str)
        self.assertEqual(recovered.zval, ["some", "z", "values"])

    def test_xml_serialise(self):
        xml_bytes = self.model.to_xml(pretty_print=True)
        _write("serializationsample.xml", xml_bytes)
        _validate_xml(xml_bytes, "serializationExample.vo-dml.xsd", self)
        self.assertIn(b"<SomeContent", xml_bytes)

    def test_xml_round_trip(self):
        from org.ivoa.dm.serializationsample.MyModel import SomeContent
        xml_bytes = self.model.to_xml(pretty_print=True)
        recovered = SomeContent.from_xml(xml_bytes)
        self.assertEqual(recovered.zval, self.model.someContent[0].zval)




class PythonNonModelReadTest(unittest.TestCase):
    """
    Reads the Python-produced serialisation files from interoperability/python/ and
    checks for parsing/validation errors. It does not use the model files for reading
    but does it with direct JSON parsing and ElementTree for XML.

    The tests were trained on the Java examples, so they expect the same structure and content as the Java files.

    The Java VODML serialisation wraps model objects in a container with a ``refs``
    section (objects referenced by ID or natural key) and a ``content`` list (typed
    with ``@type``).  These tests parse both the JSON and XML representations and
    validate that the expected model data can be extracted without errors, providing
    a measure of Java ↔ Python interoperability.
    """



    # ------------------------------------------------------------------ helpers

    @staticmethod
    def _find_content(java_model_root: dict, type_fragment: str) -> dict | None:
        """Return the first content entry whose ``@type`` contains *type_fragment*."""
        for item in java_model_root.get("content", []):
            if type_fragment in item.get("@type", ""):
                return item
        return None

    @staticmethod
    def _parse_xml_root(path: Path) -> ET.Element:
        """Return the root Element of the parsed XML file at *path*."""
        return ET.parse(str(path)).getroot()



    # ------------------------------------------------------------------ sample JSON

    def test_sample_json_source_catalogue(self):
        """Parse Python sample.json and validate SourceCatalogue data."""
        with open(_INTEROP_DIR / "sample.json") as fh:
            data = json.load(fh)

        root = data.get("SampleModel", {})
        self.assertIn("refs", root, "Missing 'refs' section in Java sample.json")
        self.assertIn("content", root, "Missing 'content' section in Java sample.json")

        sc = self._find_content(root, "SourceCatalogue")
        self.assertIsNotNone(sc, "SourceCatalogue not found in Java sample.json content")
        self.assertEqual(sc["name"], "testCat")

        entries = sc.get("entry", [])
        self.assertEqual(len(entries), 1, "Expected exactly 1 entry in SourceCatalogue")
        entry = entries[0]
        self.assertEqual(entry["name"], "testSource")
        self.assertEqual(entry["classification"], "AGN")
        self.assertEqual(len(entry.get("luminosity", [])), 2)

        position = entry["position"]
        self.assertAlmostEqual(position["longitude"]["value"], 2.5)
        self.assertAlmostEqual(position["latitude"]["value"], 52.5)

    def test_sample_json_photometric_system(self):
        """Parse Python sample.json and validate PhotometricSystem data."""
        with open(_INTEROP_DIR / "sample.json") as fh:
            data = json.load(fh)

        root = data.get("SampleModel", {})
        ps = self._find_content(root, "PhotometricSystem")
        self.assertIsNotNone(ps, "PhotometricSystem not found in Java sample.json")
        self.assertEqual(ps["detectorType"], 1)

        filters = ps.get("photometryFilter", [])
        self.assertEqual(len(filters), 2)
        names = {f["name"] for f in filters}
        self.assertIn("C-Band", names)
        self.assertIn("L-Band", names)

    # ------------------------------------------------------------------ sample XML

    def test_sample_xml_source_catalogue(self):
        """Parse Python sample.xml and validate SourceCatalogue data."""
        root = self._parse_xml_root(_INTEROP_DIR / "sample.xml")

        # The Java XML uses dotted element names like `catalog.inner.SourceCatalogue`
        sc_el = next(
            (el for el in root.iter() if "SourceCatalogue" in self),
            None,
        )
        self.assertIsNotNone(sc_el, "SourceCatalogue element not found in Java sample.xml")

        name_el = sc_el.find("name")
        self.assertIsNotNone(name_el, "No <name> child under SourceCatalogue")
        self.assertEqual(name_el.text, "testCat")

        # Find entry elements (may be wrapped)
        entries = list(sc_el.iter("entry"))
        self.assertGreaterEqual(len(entries), 1, "No <entry> elements found")
        entry = entries[0]

        name_sub = entry.find("name")
        self.assertIsNotNone(name_sub)
        self.assertEqual(name_sub.text, "testSource")

        classification = entry.find("classification")
        self.assertIsNotNone(classification)
        self.assertEqual(classification.text, "AGN")

    # ------------------------------------------------------------------ lifecycle JSON

    def test_lifecycle_json_atest2(self):
        """Parse Python lifecycle.json and validate ATest2 data."""
        with open(_INTEROP_DIR / "lifecycle.json") as fh:
            data = json.load(fh)

        root = data.get("LifecycleTestModel", {})
        self.assertIn("content", root, "Missing 'content' in Java lifecycle.json")

        atest2 = self._find_content(root, "ATest2")
        self.assertIsNotNone(atest2, "ATest2 not found in Java lifecycle.json")

        atest = atest2.get("atest", {})
        self.assertIsNotNone(atest, "Missing 'atest' inside ATest2")

        contained = atest.get("contained", [])
        self.assertEqual(len(contained), 2, "Expected 2 contained items in ATest.contained")
        test2_values = [c["test2"] for c in contained]
        self.assertIn("firstcontained", test2_values)
        self.assertIn("secondContained", test2_values)

        refandcontained = atest.get("refandcontained", [])
        self.assertEqual(len(refandcontained), 2, "Expected 2 items in refandcontained")

    # ------------------------------------------------------------------ lifecycle XML

    def test_lifecycle_xml_atest2(self):
        """Parse Python lifecycle.xml and validate ATest2 data."""
        root = self._parse_xml_root(_INTEROP_DIR / "lifecycle.xml")

        atest2 = root.find(".//aTest2")
        self.assertIsNotNone(atest2, "<aTest2> not found in lifecycle.xml")

        atest_el = atest2.find("atest")
        self.assertIsNotNone(atest_el, "No <atest> child inside <aTest2>")

        # contained is a wrapper element that itself contains <contained> children
        contained_wrapper = atest_el.find("contained")
        self.assertIsNotNone(contained_wrapper, "No <contained> wrapper under <atest>")
        contained_items = list(contained_wrapper.findall("contained"))
        self.assertEqual(len(contained_items), 2, "Expected 2 <contained> items")
        test2_texts = [c.findtext("test2") for c in contained_items]
        self.assertIn("firstcontained", test2_texts)
        self.assertIn("secondContained", test2_texts)

    # ------------------------------------------------------------------ serialisation example JSON

    def test_serializationsample_json_somecontent(self):
        """Parse Python serializationsample.json and validate SomeContent data."""
        with open(_INTEROP_DIR / "serializationsample.json") as fh:
            data = json.load(fh)

        root = data.get("MyModelModel", {})
        sc = self._find_content(root, "SomeContent")
        self.assertIsNotNone(sc, "SomeContent not found in Java serializationsample.json")

        self.assertEqual(sc.get("zval", []), ["some", "z", "values"])

        con = sc.get("con", [])
        self.assertEqual(len(con), 2, "Expected 2 'con' items")
        types = [c.get("@type", "") for c in con]
        self.assertTrue(any("Dcont" in t for t in types), "Dcont not found in con types")
        self.assertTrue(any("Econt" in t for t in types), "Econt not found in con types")

    # ------------------------------------------------------------------ serialisation example XML

    def test_serializationsample_xml_somecontent(self):
        """Parse Python serializationsample.xml and validate SomeContent data."""
        root = self._parse_xml_root(_INTEROP_DIR / "serializationsample.xml")

        sc_el = root.find(".//someContent")
        self.assertIsNotNone(sc_el, "<someContent> not found in serializationsample.xml")

        # zval items are wrapped in <zvals><zval>...</zval></zvals>
        zvals_el = sc_el.find("zvals")
        self.assertIsNotNone(zvals_el, "No <zvals> element under <someContent>")
        zvals = [el.text for el in zvals_el.findall("zval")]
        self.assertEqual(zvals, ["some", "z", "values"])

        con_el = sc_el.find("con")
        self.assertIsNotNone(con_el, "No <con> element under <someContent>")
        base_c_items = list(con_el.iter("baseC"))
        self.assertEqual(len(base_c_items), 2, "Expected 2 <baseC> items")

        # xsi:type should distinguish Dcont from Econt
        xsi_type_attr = "{http://www.w3.org/2001/XMLSchema-instance}type"
        xtypes = [el.get(xsi_type_attr, "") for el in base_c_items]
        self.assertTrue(any("Dcont" in xt for xt in xtypes), "Dcont xsi:type not found")
        self.assertTrue(any("Econt" in xt for xt in xtypes), "Econt xsi:type not found")

    # ------------------------------------------------------------------ XML schema validation

class PythonModelReadJavaTest(unittest.TestCase):
    """ This is a placeholder for when it is worth doing the reading of the java serialized instances with the python model - i.e. all the other test need to pass...
    """
    _JAVA_DIR = Path(__file__).parent.parent.parent / "interoperability" / "java"

        # ------------------------------------------------------------------ file existence

    def test_java_interop_files_exist(self):
        """All expected Java interoperability files must be present."""
        expected = [
            "sample.json", "sample.xml",
            "lifecycle.json", "lifecycle.xml",
            "serializationsample.json", "serializationsample.xml",
        ]
        missing = [f for f in expected if not (self._JAVA_DIR / f).exists()]
        self.assertFalse(
            missing,
            f"Java interop files not found: {missing}  (run :sample:test first)",
        )


if __name__ == "__main__":
    unittest.main()
