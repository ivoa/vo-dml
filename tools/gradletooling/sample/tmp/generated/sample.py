from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional
from generated.filter import PhotometryFilter
from generated.ivoa import RealQuantity

__NAMESPACE__ = "http://ivoa.net/vodml/sample/sample"


@dataclass
class AstroObject:
    label: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )


@dataclass
class SkyCoordinateFrame:
    name: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    documentURI: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    equinox: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    system: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )


@dataclass
class SkyError:
    pass


@dataclass
class Testing:
    plain: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    arrayIsh: List[str] = field(
        default_factory=list,
        metadata={
            "type": "Element",
            "namespace": "",
            "min_occurs": 1,
        }
    )
    unbounded: List[str] = field(
        default_factory=list,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )


class luminosityType(Enum):
    MAGNITUDE = "MAGNITUDE"
    FLUX = "FLUX"


class sourceClassification(Enum):
    STAR = "STAR"
    GALAXY = "GALAXY"
    AGN = "AGN"
    PLANET = "PLANET"
    UNKNOWN = "UNKNOWN"


@dataclass
class AlignedEllipse(SkyError):
    longError: Optional[float] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    latError: Optional[float] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )


@dataclass
class CircleError(SkyError):
    radius: Optional[float] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )


@dataclass
class GenericEllipse(SkyError):
    major: Optional[float] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    minor: Optional[float] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    pa: Optional[float] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )


@dataclass
class LuminosityMeasurement:
    value: Optional[RealQuantity] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    error: Optional[RealQuantity] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    description: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    type: Optional[luminosityType] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    filter: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )


@dataclass
class SkyCoordinate:
    longitude: Optional[RealQuantity] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    latitude: Optional[RealQuantity] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    frame: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )


@dataclass
class references:
    skyCoordinateFrame: List[SkyCoordinateFrame] = field(
        default_factory=list,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    photometryFilter: List[PhotometryFilter] = field(
        default_factory=list,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )


@dataclass
class AbstractSource(AstroObject):
    name: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    description: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    position: Optional[SkyCoordinate] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    classification: Optional[sourceClassification] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    luminosity: List[LuminosityMeasurement] = field(
        default_factory=list,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )


@dataclass
class SDSSSource(AbstractSource):
    positionError: Optional[SkyError] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )


@dataclass
class Source(AbstractSource):
    positionError: Optional[SkyError] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )


@dataclass
class SourceCatalogue:
    name: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    entry: List[AbstractSource] = field(
        default_factory=list,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    aTest: Optional[Testing] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    aTestMore: Optional[Testing] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )


@dataclass
class TwoMassSource(AbstractSource):
    positionError: Optional[SkyError] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )


@dataclass
class sampleModel:
    class Meta:
        namespace = "http://ivoa.net/vodml/sample/sample"

    refs: Optional[references] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    LuminosityMeasurement: List[LuminosityMeasurement] = field(
        default_factory=list,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    SDSSSource: List[SDSSSource] = field(
        default_factory=list,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    Source: List[Source] = field(
        default_factory=list,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    TwoMassSource: List[TwoMassSource] = field(
        default_factory=list,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    Testing: List[Testing] = field(
        default_factory=list,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    SourceCatalogue: List[SourceCatalogue] = field(
        default_factory=list,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
