from datetime import datetime
import unittest


from xsdata.formats.dataclass.serializers import XmlSerializer
from xsdata.formats.dataclass.context import XmlContext
from xsdata.formats.dataclass.serializers.config import SerializerConfig


from org.ivoa.dm.filter.filter import PhotometryFilter
from org.ivoa.dm.samplemodel.sample_catalog import LuminosityMeasurement, SkyCoordinateFrame, AlignedEllipse
from org.ivoa.dm.samplemodel.sample_catalog import SDSSSource
from org.ivoa.dm.samplemodel.sample_catalog import SkyCoordinate
from org.ivoa.dm.samplemodel.sample_catalog_inner import SourceCatalogue
from org.ivoa.dm.ivoa import *
from org.ivoa.dm.samplemodel.sample_catalog import SourceClassification
from org.ivoa.dm.samplemodel.sample_catalog import LuminosityType


class MyTestCase(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        jansky = Unit("Jy")
        degree = Unit("degree")
        GHz = Unit("GHz")
        frame = SkyCoordinateFrame(name="J2000", equinox="J2000.0", documentURI=anyURI("http://coord.net"))

        ellipseError = AlignedEllipse(.2, .1)
        # sdss =  SDSSSource(positionError=ellipseError)# UNUSED, but just checking position error subsetting.
        # sdss.setPositionError(ellipseError)
        # theError = sdss.positionError

        cls.sc = SourceCatalogue(name="testCat",
                                 entry=[SDSSSource(name="testSource", classification=SourceClassification.AGN,
                                                   position=SkyCoordinate(frame=frame,
                                                                          latitude=RealQuantity(value=52.5, unit=degree),
                                                                          longitude=RealQuantity(value=2.5, unit=degree)),
                                                   positionError=ellipseError,
                                                   # note subsetting forces compile need AlignedEllipse
                                                   luminosity=[
                                                       LuminosityMeasurement(description="lummeas",
                                                                             type=LuminosityType.FLUX,
                                                                             value=RealQuantity(value=2.5, unit=jansky),
                                                                             error=RealQuantity(value=.25, unit=jansky),
                                                                             filter=PhotometryFilter(bandName="C-Band",
                                                                                                     spectralLocation=
                                                                                                     RealQuantity(value=5.0,
                                                                                                                  unit=GHz),
                                                                                                     dataValidityFrom=datetime.now(),
                                                                                                     dataValidityTo=datetime.now(),
                                                                                                     description="radio band",
                                                                                                     name="C-Band measure")),
                                                       LuminosityMeasurement(description="lummeas2",
                                                                             type=LuminosityType.FLUX,
                                                                             value=RealQuantity(value=3.5, unit=jansky),
                                                                             error=RealQuantity(value=.25, unit=jansky),
                                                                             filter=PhotometryFilter(bandName="L-Band",
                                                                                                     spectralLocation=RealQuantity(
                                                                                                         value=1.5, unit=GHz),
                                                                                                     dataValidityFrom=datetime.now(),
                                                                                                     dataValidityTo=datetime.now(),
                                                                                                     description="radio band",
                                                                                                     name="L-Band"))
                                                   ]

                                                   )]

                                 )

    def test_something(self):
        context = XmlContext()
        config = SerializerConfig(pretty_print=True)
        serializer = XmlSerializer(config=config, context=context)
        print(serializer.render(self.sc))
        assert self.sc is not None  # TODO do some meaningful tests


if __name__ == '__main__':
    unittest.main()
