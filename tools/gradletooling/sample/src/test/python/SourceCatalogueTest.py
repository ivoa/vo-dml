from datetime import datetime
import unittest


from xsdata.formats.dataclass.serializers import XmlSerializer
from xsdata.formats.dataclass.serializers.config import SerializerConfig


from org.ivoa.dm.filter.filter import PhotometryFilter
from org.ivoa.dm.samplemodel.sample_catalog import LuminosityMeasurement, SkyCoordinateFrame, AlignedEllipse
from org.ivoa.dm.samplemodel.sample_catalog import SDSSSource
from org.ivoa.dm.samplemodel.sample_catalog import SkyCoordinate
from org.ivoa.dm.samplemodel.sample_catalog_inner import SourceCatalogue
from org.ivoa.dm.ivoa.ivoa import *
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
                                                                          latitude=RealQuantity(52.5, degree),
                                                                          longitude=RealQuantity(2.5, degree)),
                                                   positionError=ellipseError,
                                                   # note subsetting forces compile need AlignedEllipse
                                                   luminosity=[
                                                       LuminosityMeasurement(description="lummeas",
                                                                             type=LuminosityType.FLUX,
                                                                             value=RealQuantity(2.5, jansky),
                                                                             error=RealQuantity(.25, jansky),
                                                                             filter=PhotometryFilter(bandName="C-Band",
                                                                                                     spectralLocation=
                                                                                                     RealQuantity(5.0,
                                                                                                                  GHz),
                                                                                                     dataValidityFrom=datetime.now(),
                                                                                                     dataValidityTo=datetime.now(),
                                                                                                     description="radio band",
                                                                                                     name="C-Band measure")),
                                                       LuminosityMeasurement(description="lummeas2",
                                                                             type=LuminosityType.FLUX,
                                                                             value=RealQuantity(3.5, jansky),
                                                                             error=RealQuantity(.25, jansky),
                                                                             filter=PhotometryFilter(bandName="L-Band",
                                                                                                     spectralLocation=RealQuantity(
                                                                                                         1.5, GHz),
                                                                                                     dataValidityFrom=datetime.now(),
                                                                                                     dataValidityTo=datetime.now(),
                                                                                                     description="radio band",
                                                                                                     name="L-Band"))
                                                   ]

                                                   )]

                                 )

    def test_something(self):
        config = SerializerConfig(pretty_print=True)
        serializer = XmlSerializer(config=config)
        print(serializer.render(self.sc))
        assert self.sc is not None  # TODO do some meaningful tests


if __name__ == '__main__':
    unittest.main()
