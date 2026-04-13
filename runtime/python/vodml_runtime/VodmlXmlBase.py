#  Copyright (c) 2026. Paul Harrison, University of Manchester
from pydantic import BaseModel, ConfigDict, field_serializer
from xsdata.formats.dataclass.context import XmlContext
from xsdata.formats.dataclass.serializers import XmlSerializer
from xsdata.formats.dataclass.serializers.config import SerializerConfig
from xsdata.formats.dataclass.parsers import XmlParser

class _VodmlXmlBase(BaseModel):
    """Base class providing Pydantic BaseModel with xsdata XML serialisation."""
    model_config = ConfigDict(arbitrary_types_allowed=True)


    def to_xml(self, nsmap: dict[str, str] | None = None, pretty_print: bool = False) -> bytes:
        config = SerializerConfig(indent="  " if pretty_print else None)
        ctx = XmlContext(class_type="pydantic")
        return XmlSerializer(config=config, context=ctx).render(self, ns_map=nsmap).encode("utf-8")

    @classmethod
    def from_xml(cls, xml_bytes: bytes):
        ctx = XmlContext(class_type="pydantic")
        data = xml_bytes.decode("utf-8") if isinstance(xml_bytes, bytes) else xml_bytes
        return XmlParser(context=ctx).from_string(data, cls)

