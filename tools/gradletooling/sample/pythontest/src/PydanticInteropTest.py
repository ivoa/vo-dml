"""
Pydantic interoperability tests.

These tests create the same model instances that the Java serialisation tests produce,
re-serialise them to XML and JSON using the generated pydantic-xml models, and write
the results to interoperability/python/.  The output can then be compared with the
files in interoperability/java/ to evaluate how close the two serialisations are.
"""

import json
import unittest
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

from lxml import etree as _etree

from org.ivoa.dm.filter.filter import PhotometricSystem, PhotometryFilter
from org.ivoa.dm.ivoa import RealQuantity, Unit
from org.ivoa.dm.jpatest.jpatest import JpatestModel

from org.ivoa.dm.lifecycle.lifecycleTest import LifecycleTestModel, LifecycleTestRefs
from org.ivoa.dm.samplemodel.sample import SampleModel, SampleRefs

from org.ivoa.dm.samplemodel.sample_catalog_inner import SourceCatalogue
from org.ivoa.dm.serializationsample.MyModel import MyModelModel, MyModelRefs

# Output directory (relative to the sample project root).
_SAMPLE_DIR = Path(__file__).parent.parent.parent
_INTEROP_DIR = _SAMPLE_DIR / "interoperability" / "python"
_JAVA_DIR = _SAMPLE_DIR / "interoperability" / "java"

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


def _local_name(tag: str) -> str:
    """Return the local part of an XML tag name."""
    return tag.split("}", 1)[-1]


def _find_first(root: ET.Element, local_name: str) -> ET.Element | None:
    """Return the first element in *root* whose local name matches *local_name*."""
    return next((el for el in root.iter() if _local_name(el.tag) == local_name), None)


def _children_named(element: ET.Element, local_name: str) -> list[ET.Element]:
    """Return the direct children of *element* with the given local name."""
    return [child for child in list(element) if _local_name(child.tag) == local_name]


def _first_child_text(element: ET.Element, local_name: str) -> str | None:
    """Return the text of the first direct child called *local_name*."""
    child = next((c for c in list(element) if _local_name(c.tag) == local_name), None)
    return child.text if child is not None else None


def _read_json(filename: str) -> dict:
    with open(_INTEROP_DIR / filename, encoding="utf-8") as fh:
        return json.load(fh)


def _read_xml_root(filename: str) -> ET.Element:
    return ET.parse(str(_INTEROP_DIR / filename)).getroot()

def _read_java_file_as_bytes(path: str) -> bytes:
    with open(_JAVA_DIR / path, "rb") as f:
        return f.read()

class SampleModelInteropTest(unittest.TestCase):
    """
    Tests for the Sample model (SourceCatalogue / SDSSSource).

    Mirrors the Java BaseSourceCatalogueTest / SourceCatalogueTest which produce
    interoperability/java/sample.xml  and  interoperability/java/sample.json.
    """

    @classmethod
    def setUpClass(cls):
        from org.ivoa.dm.samplemodel.sample_catalog import (
            AlignedEllipse,
            LuminosityMeasurement,
            LuminosityType,
            SDSSSource,
            SkyCoordinate,
            SkyCoordinateFrame,
            SourceClassification,
        )
        jansky = Unit(value="Jy")
        degree = Unit(value="degree")
        ghz = Unit(value="GHz")

        frame = SkyCoordinateFrame(
            name="J2000",
            equinox="J2000.0",
            documentURI="http://coord.net",
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
        json_str = self.model.model_dump_json(indent=2)
        _write("sample.json", json_str)

        data = json.loads(json_str)
        self.assertEqual(data["sourceCatalogue"][0]["name"], "testCat")
        entry = data["sourceCatalogue"][0]["entry"][0]
        self.assertEqual(entry["name"], "testSource")
        self.assertEqual(entry["position"]["frame"], "J2000")
        self.assertEqual(len(entry["luminosity"]), 2)
        self.assertAlmostEqual(entry["position"]["longitude"]["value"], 2.5)
        self.assertEqual(data["photometricSystem"][0]["photometryFilter"][1]["name"], "L-Band")

    def test_json_round_trip(self):
        recovered = SampleModel.model_validate_json(self.model.model_dump_json())
        self.assertEqual(recovered.sourceCatalogue[0].name, "testCat")
        self.assertEqual(recovered.sourceCatalogue[0].entry[0].name, "testSource")
        self.assertEqual(recovered.refs.skyCoordinateFrame[0].name, "J2000")

    def test_xml_serialise(self):
        xml_bytes = self.model.full_model_to_xml(pretty_print=True)
        _write("sample.xml", xml_bytes)
        _validate_xml(xml_bytes, "Sample.vo-dml.xsd", self)
        root = ET.fromstring(xml_bytes)
        self.assertEqual(_local_name(root.tag), "sampleModel")
        source_catalogue = _find_first(root, "sourceCatalogue")
        self.assertIsNotNone(source_catalogue)
        self.assertEqual(_first_child_text(source_catalogue, "name"), "testCat")
        self.assertEqual(_first_child_text(_find_first(source_catalogue, "entry"), "name"), "testSource")

    def test_read_java_serialization_xml(self):
        recovered = SampleModel.from_xml( _read_java_file_as_bytes("sample.xml"))
        self.assertEqual(recovered.sourceCatalogue[0].name, "testCat")
        self.assertEqual(recovered.sourceCatalogue[0].entry[0].name, "testSource")
        self.assertEqual(recovered.photometricSystem[0].photometryFilter[0].name, "C-Band")


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
        #FIXME really need to add equivalent of the java processReferences() runtime functionality to set up the ids for references
        ref1 = ReferredTo(id="lifecycleTest-ReferredTo_1011", test1=3)
        rc1 = ReferredLifeCycle(id="lifecycleTest-ReferredLifeCycle_1012", test3="rc1")
        rc2 = ReferredLifeCycle(id="lifecycleTest-ReferredLifeCycle_1013", test3="rc2")
        atest = ATest(
            ref1=ref1,
            contained=[
                Contained(test2="firstcontained"),
                Contained(test2="secondContained"),
            ],
            refandcontained=[rc1, rc2],
            contained2=ATest4(lowr=rc1.id),
        )
        top = ATest2(atest=atest, refcont=rc1, refagg=[ref1])
        cls.model=LifecycleTestModel(aTest2=[top],refs=LifecycleTestRefs(referredTo=[ref1,rc1, rc2]))

    def test_json_serialise(self):
        json_str = self.model.model_dump_json(indent=2)
        _write("lifecycle.json", json_str)

        data = json.loads(json_str)
        self.assertEqual(data["refs"]["referredTo"][0]["test1"], 3)
        atest2 = data["aTest2"][0]
        self.assertEqual(atest2["refcont"], "lifecycleTest-ReferredLifeCycle_1012")
        self.assertEqual(len(atest2["atest"]["contained"]), 2)
        self.assertEqual(atest2["atest"]["refandcontained"][1]["test3"], "rc2")

    def test_json_round_trip(self):
        recovered = LifecycleTestModel.model_validate_json(self.model.model_dump_json())
        self.assertEqual(recovered.aTest2[0].atest.contained[0].test2, "firstcontained")
        self.assertEqual(recovered.aTest2[0].refcont, "lifecycleTest-ReferredLifeCycle_1012")

    def test_xml_serialise(self):
        xml_bytes = self.model.full_model_to_xml(pretty_print=True)
        _write("lifecycle.xml", xml_bytes)
        _validate_xml(xml_bytes, "lifecycleTest.vo-dml.xsd", self)
        root = ET.fromstring(xml_bytes)
        self.assertEqual(_local_name(root.tag), "lifecycleTestModel")
        atest2 = _find_first(root, "aTest2")
        self.assertIsNotNone(atest2)
        self.assertEqual(_first_child_text(atest2, "refcont"), "lifecycleTest-ReferredLifeCycle_1012")
        self.assertIn("firstcontained", "".join(el.text or "" for el in root.iter() if _local_name(el.tag) == "test2"))

    def test_read_java_serialization_xml(self):
        recovered = LifecycleTestModel.from_xml( _read_java_file_as_bytes("lifecycle.xml"))
        self.assertEqual(len(recovered.aTest2[0].atest.contained), 2)
        self.assertEqual(recovered.aTest2[0].atest.contained2.lowr, "lifecycleTest-ReferredLifeCycle_1012")


class SerializationExampleInteropTest(unittest.TestCase):
    """
    Tests for the serialisation example model (MyModel).

    Mirrors the Java SerializationExampleTest which produces
    interoperability/java/serializationsample.xml  and
    interoperability/java/serializationsample.json.
    """

    @classmethod
    def setUpClass(cls):
        from org.ivoa.dm.serializationsample.MyModel import Refa, Refb, SomeContent, altURL, ivoid
        from org.ivoa.dm.serializationsample.MyModel_types import Dcont, Econt

        refa = Refa(id="MyModel-Refa_1000", val=altURL(value="urn:value"))
        refb = Refb(name="naturalkey", val=ivoid(value="ivo:val"))
        cls.model = MyModelModel(
            someContent=[
                SomeContent(
                    ref1=refa.id,
                    ref2=refb.name,
                    zval=["some", "z", "values"],
                    con=[
                        Dcont(bname="dval", dval="N1"),
                        Econt(bname="eval", evalue="cube"),
                    ],
                    uri="urn:uri"
                )
            ],
            refs=MyModelRefs(refa=[refa], refb=[refb]),
        )

    def test_json_serialise(self):
        json_str = self.model.model_dump_json(indent=2)
        _write("serializationsample.json", json_str)

        data = json.loads(json_str)
        self.assertEqual(data["refs"]["refa"][0]["id"], "MyModel-Refa_1000")
        content = data["someContent"][0]
        self.assertEqual(content["ref1"], "MyModel-Refa_1000")
        self.assertEqual(content["ref2"], "naturalkey")
        self.assertEqual(content["zval"], ["some", "z", "values"])
        self.assertEqual(len(content["con"]), 2)

    def test_json_round_trip(self):
        recovered = MyModelModel.model_validate_json(self.model.model_dump_json())
        self.assertEqual(recovered.someContent[0].zval, ["some", "z", "values"])
        self.assertEqual(recovered.refs.refb[0].name, "naturalkey")

    def test_xml_serialise(self):
        xml_bytes = self.model.full_model_to_xml(pretty_print=True)
        _write("serializationsample.xml", xml_bytes)
        _validate_xml(xml_bytes, "serializationExample.vo-dml.xsd", self)
        root = ET.fromstring(xml_bytes)
        self.assertEqual(_local_name(root.tag), "MyModelModel")
        some_content = _find_first(root, "someContent")
        self.assertIsNotNone(some_content)
        self.assertEqual(_first_child_text(some_content, "ref1"), "MyModel-Refa_1000")
        zvals = [el.text for el in root.iter() if _local_name(el.tag) == "zval"]
        self.assertEqual(zvals, ["some", "z", "values"])


    def test_read_java_serialization_xml(self):
        from org.ivoa.dm.serializationsample.MyModel import Refa
        from_java = MyModelModel.from_xml( _read_java_file_as_bytes("serializationsample.xml"))
        self.assertIsInstance(from_java.someContent[0].ref1, Refa)

class JpatestModelInteropTest(unittest.TestCase):
    """Round-trip tests for the jpatest model wrapper."""

    @classmethod
    def setUpClass(cls):
        from org.ivoa.dm.jpatest.jpatest import (
            ADtype,
            AEtype,
            Child,
            DThing,
            JpatestModel,
            JpatestRefs,
            LChild,
            Parent,
            Point,
            ReferredTo1,
            ReferredTo2,
            ReferredTo3,
        )
        ref3 = ReferredTo3(id="jpatest-ReferredTo3_1002", sval="ref in dtype", ival=3)
        ref2 = ReferredTo2(id="jpatest-ReferredTo2_1004", sval="lower ref")
        ref1 = ReferredTo1(id="jpatest-ReferredTo1_1003", sval="top level ref")

        parent = Parent(
            dval=ADtype(
                basestr="base",
                dref=ref3.id,
                intatt="intatt",
                dvalr=1.1,
                dvals="astring",
            ),
            eval=AEtype(
                basestr="basestre_e",
                dref=ref3.id,
                intatt="intatt_e",
                evalr=1.2,
                evals="evals",
            ),
            rval=ref1.id,
            cval=Child(rval=ref2.id),
            lval=[
                LChild(sval="First", ival=1),
                LChild(sval="Second", ival=2),
                LChild(sval="Third", ival=3),
            ],
            tval=DThing(p=Point(x=1.5, y=3.0), dt="thing"),
        )

        cls.model = JpatestModel(
            refs=JpatestRefs(referredTo3=[ref3], referredTo2=[ref2], referredTo1=[ref1]),
            parent=[parent],
        )

    def test_json_serialise(self):
        json_str = self.model.model_dump_json(indent=2)
        _write("jpatest.json", json_str)

        data = json.loads(json_str)
        self.assertEqual(data["refs"]["referredTo3"][0]["ival"], 3)
        parent = data["parent"][0]
        self.assertEqual(parent["dval"]["dref"], "jpatest-ReferredTo3_1002")
        self.assertEqual(parent["rval"], "jpatest-ReferredTo1_1003")
        self.assertEqual(parent["cval"]["rval"], "jpatest-ReferredTo2_1004")
        self.assertEqual([child["sval"] for child in parent["lval"]], ["First", "Second", "Third"])
        self.assertAlmostEqual(parent["tval"]["p"]["x"], 1.5)

    def test_json_round_trip(self):
        recovered = JpatestModel.model_validate_json(self.model.model_dump_json())
        parent = recovered.parent[0]
        self.assertEqual(parent.dval.intatt, "intatt")
        self.assertEqual(parent.eval.intatt, "intatt_e")
        self.assertEqual(parent.tval.p.x, 1.5)
        self.assertEqual(parent.cval.rval, "jpatest-ReferredTo2_1004")

    def test_xml_serialise(self):
        xml_bytes = self.model.full_model_to_xml(pretty_print=True)
        _write("jpatest.xml", xml_bytes)
        _validate_xml(xml_bytes, "jpatest.vo-dml.xsd", self)
        root = ET.fromstring(xml_bytes)
        self.assertEqual(_local_name(root.tag), "jpatestModel")
        parent = _find_first(root, "parent")
        self.assertIsNotNone(parent)
        self.assertEqual(_first_child_text(parent, "rval"), "jpatest-ReferredTo1_1003")
        dval = _find_first(parent, "dval")
        self.assertEqual(_first_child_text(dval, "dvals"), "astring")
        lval = _children_named(parent, "lval")
        self.assertEqual(len(lval), 1)
        lchildren = _children_named(lval[0], "lChild")
        self.assertEqual([_first_child_text(child, "sval") for child in lchildren], ["First", "Second", "Third"])

    def test_xml_round_trip(self):
        recovered = JpatestModel.from_xml(self.model.to_xml(pretty_print=True))
        parent = recovered.parent[0]
        self.assertEqual(parent.dval.basestr, "base")
        self.assertEqual(parent.eval.evals, "evals")
        self.assertEqual(parent.lval[1].ival, 2)
        self.assertEqual(parent.tval.dt, "thing")


class PythonNonModelReadTest(unittest.TestCase):
    """Validate the Python-written interoperability files without using the generated models."""

    def test_sample_json_source_catalogue(self):
        data = _read_json("sample.json")
        self.assertIn("sourceCatalogue", data)
        self.assertIn("photometricSystem", data)

        catalogue = data["sourceCatalogue"][0]
        self.assertEqual(catalogue["name"], "testCat")
        entry = catalogue["entry"][0]
        self.assertEqual(entry["name"], "testSource")
        self.assertEqual(entry["classification"], "AGN")
        self.assertEqual(entry["position"]["frame"], "J2000")

    def test_sample_json_photometric_system(self):
        data = _read_json("sample.json")
        ps = data["photometricSystem"][0]
        self.assertEqual(ps["detectorType"], 1)
        names = [item["name"] for item in ps["photometryFilter"]]
        self.assertEqual(names, ["C-Band", "L-Band"])

    def test_sample_xml_source_catalogue(self):
        root = _read_xml_root("sample.xml")
        catalogue = _find_first(root, "sourceCatalogue")
        self.assertIsNotNone(catalogue)
        self.assertEqual(_first_child_text(catalogue, "name"), "testCat")
        entry = _find_first(catalogue, "entry")
        self.assertEqual(_first_child_text(entry, "name"), "testSource")
        self.assertEqual(_first_child_text(entry, "classification"), "AGN")

    def test_lifecycle_json_atest2(self):
        data = _read_json("lifecycle.json")
        atest2 = data["aTest2"][0]
        self.assertEqual(atest2["refagg"], ["lifecycleTest-ReferredTo_1011"])
        self.assertEqual(len(atest2["atest"]["contained"]), 2)
        self.assertEqual(atest2["atest"]["contained2"]["lowr"], "lifecycleTest-ReferredLifeCycle_1012")

    def test_lifecycle_xml_atest2(self):
        root = _read_xml_root("lifecycle.xml")
        atest2 = _find_first(root, "aTest2")
        self.assertIsNotNone(atest2)
        self.assertEqual(_first_child_text(atest2, "refcont"), "lifecycleTest-ReferredLifeCycle_1012")
        contained_values = [el.text for el in root.iter() if _local_name(el.tag) == "test2"]
        self.assertEqual(contained_values, ["firstcontained", "secondContained"])

    def test_serializationsample_json_somecontent(self):
        data = _read_json("serializationsample.json")
        content = data["someContent"][0]
        self.assertEqual(content["zval"], ["some", "z", "values"])
        self.assertEqual(content["ref1"], "MyModel-Refa_1000")
        self.assertEqual(content["ref2"], "naturalkey")
        self.assertEqual(len(content["con"]), 2)

    def test_serializationsample_xml_somecontent(self):
        root = _read_xml_root("serializationsample.xml")
        some_content = _find_first(root, "someContent")
        self.assertIsNotNone(some_content)
        self.assertEqual(_first_child_text(some_content, "ref1"), "MyModel-Refa_1000")
        zvals = [el.text for el in root.iter() if _local_name(el.tag) == "zval"]
        self.assertEqual(zvals, ["some", "z", "values"])

    def test_jpatest_json_parent(self):
        data = _read_json("jpatest.json")
        parent = data["parent"][0]
        self.assertEqual(parent["dval"]["dvals"], "astring")
        self.assertEqual(parent["eval"]["evals"], "evals")
        self.assertEqual(parent["cval"]["rval"], "jpatest-ReferredTo2_1004")
        self.assertEqual(parent["tval"]["dt"], "thing")

    def test_jpatest_xml_parent(self):
        root = _read_xml_root("jpatest.xml")
        parent = _find_first(root, "parent")
        self.assertIsNotNone(parent)
        self.assertEqual(_first_child_text(parent, "rval"), "jpatest-ReferredTo1_1003")
        self.assertEqual(_first_child_text(_find_first(parent, "tval"), "dt"), "thing")
        lvals = _children_named(parent, "lval")
        self.assertEqual(len(lvals), 1)
        lchildren = _children_named(lvals[0], "lChild")
        self.assertEqual([_first_child_text(child, "sval") for child in lchildren], ["First", "Second", "Third"])


class PythonModelReadJavaTest(unittest.TestCase):
    """Sanity-check that the Java interoperability fixtures exist."""

    def test_java_interop_files_exist(self):
        expected = [
            "sample.json",
            "sample.xml",
            "lifecycle.json",
            "lifecycle.xml",
            "serializationsample.json",
            "serializationsample.xml",
            "jpatest.json",
            "jpatest.xml",
        ]
        missing = [f for f in expected if not (_JAVA_DIR / f).exists()]
        self.assertFalse(
            missing,
            f"Java interop files not found: {missing}  (run :sample:test first)",
        )


if __name__ == "__main__":
    unittest.main()
