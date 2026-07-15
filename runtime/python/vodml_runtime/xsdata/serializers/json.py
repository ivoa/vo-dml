import json
from collections.abc import Callable
from dataclasses import dataclass, field
from io import StringIO
from typing import Any, TextIO

from xsdata.formats.dataclass.models.elements import XmlVar

from vodml_runtime.xsdata.serializers import DictEncoder


@dataclass
class JsonSerializer(DictEncoder):
    """Json serializer for data classes.

    Args:
        config: The serializer config instance
        context: The models context instance
        dict_factory: Dictionary factory
        dump_factory: Json dump factory e.g. json.dump
    """

    dump_factory: Callable = field(default=json.dump)

    def render(self, obj: Any) -> str:
        """Serialize the input model instance to json string.

        Args:
            obj: The input model instance

        Returns:
            The serialized json string output.
        """
        output = StringIO()
        self.write(output, obj)
        return output.getvalue()

    def write(self, out: TextIO, obj: Any) -> None:
        """Serialize the given object to the output text stream.

        Args:
            out: The output text stream
            obj: The input model instance to serialize
        """
        if hasattr(obj, "Meta"):
            self.dump_factory(self.dict_factory(((obj.Meta.utype, self.encode(obj)), )), out, indent=self.config.indent)
        else:
            self.dump_factory(self.encode(obj), out, indent=self.config.indent)
