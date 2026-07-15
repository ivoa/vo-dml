from collections.abc import Callable, Iterator
from dataclasses import dataclass, field
from enum import Enum
from typing import Any

from xsdata.formats.converter import converter
from xsdata.formats.dataclass.context import XmlContext
from xsdata.formats.dataclass.models.elements import XmlVar
from xsdata.formats.dataclass.serializers.config import SerializerConfig
from xsdata.utils import collections


def filter_none(x: tuple) -> dict:
    """Convert a key-value pairs to dict, ignoring None values.

    Args:
        x: Key-value pairs

    Returns:
        The filtered dictionary.
    """
    return {k: v for k, v in x if v is not None}


class DictFactory:
    """Dictionary factory types."""

    FILTER_NONE = filter_none


@dataclass
class DictEncoder:
    """Json serializer for data classes.

    Args:
        config: The serializer config instance
        context: The models context instance
        dict_factory: Dictionary factory
    """

    config: SerializerConfig = field(default_factory=SerializerConfig)
    context: XmlContext = field(default_factory=XmlContext)
    dict_factory: Callable = field(default=dict)

    def encode(
        self,
        value: Any,
        var: XmlVar | None = None,
        wrapped: bool = False,
    ) -> Any:
        """Convert a value to a dictionary object.

        Args:
            value: The input value
            var: The xml var instance
            wrapped: Whether this is a wrapped value

        Returns:
            The converted json serializable value.
        """
        if value is None:
            return None

        if var is None:
            if collections.is_array(value):
                return list(map(self.encode, value))

            return self.dict_factory(self.next_value(value))

        if var.is_idref and self.context.class_type.is_model(value):
            key: list[str] = []
            for cls in value.__class__.__mro__:
                cls_meta = cls.__dict__.get("Meta")
                if cls_meta is not None and hasattr(cls_meta, "key"):
                    key = list(cls_meta.key)
                    break
            key_value = "_".join(str(getattr(value, k)) for k in key)
            return key_value
            
        if var and var.wrapper and not wrapped:
            return self.dict_factory(((var.local_name, self.encode(value, var, True)),))

        if self.context.class_type.is_model(value):
            polymorphic_count = sum(1 for b in value.__class__.__mro__ if hasattr(b, 'Meta') and hasattr(b.Meta, 'utype'))
            encoded = self.dict_factory(self.next_value(value))
            if polymorphic_count > 0:
                utype = value.__class__.Meta.utype
                return self.dict_factory(((utype, encoded),))
            return encoded

        if collections.is_array(value):
            return type(value)(self.encode(val, var, wrapped) for val in value)

        if isinstance(value, (dict, int, float, str, bool)):
            return value

        if isinstance(value, Enum):
            return self.encode(value.value, var, wrapped)

        return converter.serialize(value, format=var.format)

    def next_value(self, obj: Any) -> Iterator[tuple[str, Any]]:
        """Fetch the next value of a model instance to convert.

        Args:
            obj: The input model instance

        Yields:
            An iterator of field name and value tuples.
        """
        ignore_optionals = self.config.ignore_default_attributes
        meta = self.context.build(obj.__class__, globalns=self.config.globalns)

        for var in meta.get_all_vars():
            value = getattr(obj, var.name)
            if (
                not ignore_optionals
                or not var.is_optional(value)
            ):
                name = var.name
                if name == "id": # this is kludge!
                    name = "_id"

                if var.wrapper:
                    yield var.wrapper, self.encode(value, var, True)
                else:
                    yield name, self.encode(value, var)

