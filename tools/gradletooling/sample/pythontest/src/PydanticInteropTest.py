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
from datetime import datetime, timezone
from pathlib import Path

from org.ivoa.dm.filter.filter import PhotometricSystem, PhotometryFilter
from org.ivoa.dm.ivoa import RealQuantity, Unit, anyURI
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

# Output directory (relative to the sample project root).
_INTEROP_DIR = Path(__file__).parent.parent.parent / "interoperability" / "python"


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

    # ------------------------------------------------------------------
    # JSON
    # ------------------------------------------------------------------

    def test_json_serialise(self):
        """Serialise the SourceCatalogue to JSON and write to interoperability/python/."""
        payload = {
            "sourceCatalogue": json.loads(self.sc.model_dump_json()),
            "photometricSystem": json.loads(self.ps.model_dump_json()),
        }
        content = json.dumps(payload, indent=2)
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
        json_str = self.sc.model_dump_json()
        recovered = SourceCatalogue.model_validate_json(json_str)
        self.assertEqual(recovered.name, self.sc.name)
        self.assertEqual(len(recovered.entry), 1)

    # ------------------------------------------------------------------
    # XML
    # ------------------------------------------------------------------

    def test_xml_serialise(self):
        """Serialise the SourceCatalogue to XML and write to interoperability/python/."""
        xml_bytes = self.sc.to_xml(pretty_print=True)
        _write("sample.xml", xml_bytes)
        # Basic check: output is non-empty XML
        self.assertIn(b"<SourceCatalogue", xml_bytes)
        self.assertIn(b"testCat", xml_bytes)
        self.assertIn(b"testSource", xml_bytes)

    def test_xml_round_trip(self):
        """Verify that the XML output can be read back by pydantic-xml."""
        xml_bytes = self.sc.to_xml(pretty_print=True)
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
        cls.top = ATest2(atest=atest, refcont=rc1, refagg=[ref1])

    def test_json_serialise(self):
        json_str = self.top.model_dump_json(indent=2)
        _write("lifecycle.json", json_str)
        data = json.loads(json_str)
        self.assertIn("atest", data)
        self.assertEqual(len(data["atest"]["contained"]), 2)

    def test_json_round_trip(self):
        from org.ivoa.dm.lifecycle.lifecycleTest import ATest2
        json_str = self.top.model_dump_json()
        recovered = ATest2.model_validate_json(json_str)
        self.assertEqual(len(recovered.atest.contained), 2)

    def test_xml_serialise(self):
        xml_bytes = self.top.to_xml(pretty_print=True)
        _write("lifecycle.xml", xml_bytes)
        self.assertIn(b"<ATest2", xml_bytes)
        self.assertIn(b"firstcontained", xml_bytes)

    def test_xml_round_trip(self):
        from org.ivoa.dm.lifecycle.lifecycleTest import ATest2
        xml_bytes = self.top.to_xml(pretty_print=True)
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
        )
        from org.ivoa.dm.serializationsample.MyModel_types import BaseC, Dcont, Econt

        refa = Refa(val=altURL(value=anyURI(value="urn:value")))
        refb = Refb(
            name="naturalkey",
            val=ivoid(value=anyURI(value="ivo:val")),
        )
        cls.content = SomeContent(
            ref1=refa,
            ref2=refb,
            zval=["some", "z", "values"],
            con=[
                Dcont(bname="dval", dval="N1"),
                Econt(bname="eval", evalue="cube"),
            ],
        )

    def test_json_serialise(self):
        json_str = self.content.model_dump_json(indent=2)
        _write("serializationsample.json", json_str)
        data = json.loads(json_str)
        self.assertEqual(data["zval"], ["some", "z", "values"])
        self.assertEqual(len(data["con"]), 2)

    def test_json_round_trip(self):
        from org.ivoa.dm.serializationsample.MyModel import SomeContent
        json_str = self.content.model_dump_json()
        recovered = SomeContent.model_validate_json(json_str)
        self.assertEqual(recovered.zval, ["some", "z", "values"])

    def test_xml_serialise(self):
        xml_bytes = self.content.to_xml(pretty_print=True)
        _write("serializationsample.xml", xml_bytes)
        self.assertIn(b"<SomeContent", xml_bytes)

    def test_xml_round_trip(self):
        from org.ivoa.dm.serializationsample.MyModel import SomeContent
        xml_bytes = self.content.to_xml(pretty_print=True)
        recovered = SomeContent.from_xml(xml_bytes)
        self.assertEqual(recovered.zval, self.content.zval)


if __name__ == "__main__":
    unittest.main()
