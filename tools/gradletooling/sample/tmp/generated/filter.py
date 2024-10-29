from dataclasses import dataclass, field
from typing import List, Optional
from xsdata.models.datatype import XmlDateTime
from generated.ivoa import RealQuantity

__NAMESPACE__ = "http://ivoa.net/vodml/sample/filter"


@dataclass
class references:
    pass


@dataclass
class PhotometryFilter:
    fpsIdentifier: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
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
            "required": True,
        }
    )
    bandName: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    dataValidityFrom: Optional[XmlDateTime] = field(
        kw_only=True,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": False,
        }
    )
    dataValidityTo: Optional[XmlDateTime] = field(
        kw_only=True,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": False,
        }
    )
    spectralLocation: Optional[RealQuantity] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    id: Optional[str] = field(
        default=None,
        metadata={
            "type": "Attribute",
        }
    )


@dataclass
class PhotometricSystem:
    description: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    detectorType: Optional[int] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )
    photometryFilter: List[PhotometryFilter] = field(
        default_factory=list,
        metadata={
            "type": "Element",
            "namespace": "",
            "min_occurs": 1,
        }
    )


@dataclass
class filterModel:
    class Meta:
        namespace = "http://ivoa.net/vodml/sample/filter"

    refs: Optional[references] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
    PhotometricSystem: List[PhotometricSystem] = field(
        default_factory=list,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
