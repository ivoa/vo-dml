from dataclasses import dataclass, field
from typing import Optional

__NAMESPACE__ = "http://ivoa.net/vodml/ivoa"


@dataclass
class Quantity:
    unit: Optional[str] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )


@dataclass
class references:
    pass


@dataclass
class IntegerQuantity(Quantity):
    value: Optional[int] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )


@dataclass
class RealQuantity(Quantity):
    value: Optional[float] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
            "required": True,
        }
    )


@dataclass
class ivoaModel:
    class Meta:
        namespace = "http://ivoa.net/vodml/ivoa"

    refs: Optional[references] = field(
        default=None,
        metadata={
            "type": "Element",
            "namespace": "",
        }
    )
