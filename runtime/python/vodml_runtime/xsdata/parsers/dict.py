from collections.abc import Iterable
from contextlib import suppress
from dataclasses import dataclass, field, replace
from typing import Any, get_args, get_origin, cast

from xsdata.exceptions import ParserError
from xsdata.formats.converter import converter
from xsdata.formats.dataclass.context import XmlContext
from xsdata.formats.dataclass.models.elements import XmlMeta, XmlVar
from xsdata.formats.dataclass.parsers.config import ParserConfig
from xsdata.formats.dataclass.parsers.nodes.idref import get_obj_key
from xsdata.formats.dataclass.parsers.utils import ParserUtils
from xsdata.formats.types import T
from xsdata.utils import collections
from xsdata.utils.constants import EMPTY_MAP


def _utype_of(clazz: type) -> str | None:
    """Return the ``Meta.utype`` declared directly on *clazz*, if any."""
    cls_meta = clazz.__dict__.get("Meta")
    if cls_meta is not None:
        return cls_meta.__dict__.get("utype")
    return None

def _is_referenced(clazz: type) -> bool:
    """Return True if *clazz* is a referenced type."""
    return sum(1 for b in clazz.__mro__ if hasattr(b, 'Meta') and hasattr(b.Meta, 'key')) > 0

def _is_polymorphic(clazz: type) -> bool:
    """Return True if *clazz* is a polymorphic type."""
    return sum(1 for b in clazz.__mro__ if hasattr(b, 'Meta') and hasattr(b.Meta, 'utype')) > 0

@dataclass
class DictDecoder:
    """Bind a dictionary or a list of dictionaries to data models.

    Args:
        config: Parser configuration
        context: The models context instance
    """

    config: ParserConfig = field(default_factory=ParserConfig)
    context: XmlContext = field(default_factory=XmlContext)

    def decode(self, data: list | dict, clazz: type[T] | None = None) -> T:
        """Parse the input stream into the target class type.

        If no clazz is provided, the binding context will try
        to locate it from imported dataclasses.

        Args:
            data: A dictionary or list of dictionaries
            clazz: The target class type to decode the input data

        Returns:
            An instance of the specified class representing the decoded content.
        """
        tp = self.verify_type(clazz, data)
        if not isinstance(data, list): #impl not envisaged that lists will be presented
            result = self.bind_dataclass(data, tp)
        else:
            result = [
                self.bind_dataclass(obj, tp) for obj in data
            ]  # type: ignore
        return result

    def resolve_polymorphic(self, data: dict, clazz: type[T]) -> tuple[dict, type[T]]:
        """Unwrap a VO-DML polymorphic type-hint wrapper, if present.

        Polymorphic values are serialised as a single-key object whose key is
        the concrete class' ``Meta.utype`` and whose value is the actual
        field data, e.g. ``{"MyModel:types.Dcont": {...}}``. This resolves the
        real target class (which may be ``clazz`` itself, or one of its
        subclasses) and returns the unwrapped data alongside it.

        Args:
            data: The (possibly wrapped) data value
            clazz: The statically declared/expected class

        Returns:
            A tuple of (unwrapped data, resolved class).
        """


        (key, inner), = data.items()
        candidates = set(self.context.get_subclasses(clazz))
        candidates.add(clazz)
        for candidate in candidates:
             if _utype_of(candidate) == key:
                return inner, candidate
        raise ParserError(f"Failed to resolve polymorphic type {key} for {clazz.__qualname__}")


    def _find_text_var(self, clazz: type | None) -> XmlVar | None:
        """Return the sole ``Text`` var of *clazz*, if it is a simple-content
        wrapper model (e.g. a VO-DML PrimitiveType specialisation), else None.
        """
        if clazz is None or not self.context.class_type.is_model(clazz):
            return None
        meta = self.context.build(clazz)
        for var in meta.get_all_vars():
            if var.is_text:
                return var
        return None

    def verify_type(self, clazz: type[T] | None, data: dict | list) -> type[T]:
        """Verify the given data matches the given clazz.

        If no clazz is provided, the binding context will try
        to locate it from imported dataclasses.

        Args:
            clazz: The target class type to parse  object
            data: The loaded dictionary or list of dictionaries

        Returns:
            The clazz type to bind the loaded data.
        """
        if clazz is None:
            return self.detect_type(data)

        try:
            origin = get_origin(clazz)
            list_type = False
            if origin is list:
                list_type = True
                args = get_args(clazz)

                if len(args) != 1 or not self.context.class_type.is_model(args[0]):
                    raise TypeError

                clazz = args[0]
            elif origin is not None:
                raise TypeError
        except TypeError:
            raise ParserError(f"Invalid clazz argument: {clazz}")

        if list_type != isinstance(data, list):
            if list_type:
                raise ParserError("Document is object, expected array")
            raise ParserError("Document is array, expected object")

        return clazz  # type: ignore

    def detect_type(self, data: dict | list) -> type[T]:
        """Locate the target clazz type from the data keys.

        Args:
            data: The loaded dictionary or list of dictionaries

        Returns:
            The clazz type to bind the loaded data.
        """
        if not data:
            raise ParserError("Document is empty, can not detect type")

        keys = data[0].keys() if isinstance(data, list) else data.keys()
        clazz: type[T] | None = self.context.find_type_by_fields(set(keys))

        if clazz:
            return clazz

        raise ParserError(f"Unable to locate model with properties({list(keys)})")

    def bind_dataclass(self, data: dict, clazz: type[T]) -> T:
        """Create a new instance of the given class type with the given data.

        Args:
            data: The loaded data
            clazz: The target class type to bind the input data

        Returns:
            An instance of the class type representing the parsed content.
        """
        if set(data.keys()) == self.context.class_type.derived_keys:
            return self.bind_derived_dataclass(data, clazz)

        meta = self.context.build(clazz)
        xml_vars = meta.get_all_vars()

        params = {}
        for key, value in data.items():
            findkey = key if key != '_id' else 'id' #kludge
            var = self.find_var(xml_vars, findkey, value)

            if var is None:
                if self.config.fail_on_unknown_properties:
                    raise ParserError(f"Unknown property {clazz.__qualname__}.{findkey}")
                continue

            # Note: unlike xsdata's default XML-oriented behaviour, VO-DML JSON
            # stores the wrapped collection directly under the wrapper key
            # (no extra nesting under var.local_name), so no further unwrap
            # is required here.

            value = self.bind_value(meta, var, value)
            if var.init:
                params[var.name] = value
            else:
                ParserUtils.validate_fixed_value(meta, var, value)

        try:
            retval = self.config.class_factory(clazz, params)
            if _is_referenced(clazz):
                idref = get_obj_key(retval)
                if idref is not None:
                    self.context.idref_registry[str(idref)] = retval # this is a bit of a hack to use the idref_registry
            return retval
        except TypeError as e:
            raise ParserError(e)

    def bind_derived_dataclass(self, data: dict, clazz: type[T]) -> Any:
        """Bind the input data to the given class type.

        Examples:
            {
                "qname": "foo",
                "@type": "my:type",
                "value": {"prop": "value"}
            }

        Args:
            data: The derived element dictionary
            clazz: The target class type to bind the input data

        Returns:
            An instance of the class type representing the parsed content.
        """
        qname = data["qname"]
        xsi_type = data["@type"]
        params = data["value"]

        generic = self.context.class_type.derived_element

        if clazz is generic:
            real_clazz: type[T] | None = None
            if xsi_type:
                real_clazz = self.context.find_type(xsi_type)

            if real_clazz is None:
                raise ParserError(
                    f"Unable to locate derived model "
                    f"with properties({list(params.keys())})"
                )

            value = self.bind_dataclass(params, real_clazz)
        else:
            value = self.bind_dataclass(params, clazz)

        return generic(qname=qname, type=xsi_type, value=value)

    def bind_best_dataclass(self, data: dict, classes: Iterable[type[T]]) -> T:
        """Bind the input data to all the given classes and return best match.

        Args:
            data: The derived element dictionary
            classes: The target class types to try

        Returns:
            An instance of one of the class types representing the parsed content.
        """
        obj = None
        keys = set(data.keys())
        max_score = -1.0
        config = replace(self.config, fail_on_converter_warnings=True)
        decoder = DictDecoder(config=config, context=self.context)

        for clazz in classes:
            if not self.context.class_type.is_model(clazz):
                continue

            if self.context.local_names_match(keys, clazz):
                candidate = None
                with suppress(Exception):
                    candidate = decoder.bind_dataclass(data, clazz)

                score = self.context.class_type.score_object(candidate)
                if score > max_score:
                    max_score = score
                    obj = candidate

        if obj:
            return obj

        raise ParserError(
            f"Failed to bind object with properties({list(data.keys())}) "
            f"to any of the {[cls.__qualname__ for cls in classes]}"
        )

    def bind_value(
        self,
        meta: XmlMeta,
        var: XmlVar,
        value: Any,
        recursive: bool = False,
    ) -> Any:
        """Main entry point for binding values.

        Args:
            meta: The parent xml meta instance
            var: The xml var descriptor for the field
            value: The data value
            recursive: Whether this is a recursive call

        Returns:
            The parsed object
        """
        # xs:anyAttributes get it out of the way, it's the mapping exception!
        if var.is_attributes:
            return dict(value)

        # VO-DML idref fields are serialised as plain identifier tokens
        # (matching the referenced object's Meta.key attributes) rather than
        # embedded objects.
        def _get_idref(_val):
            retval = self.context.idref_registry.get(str(_val))  # hack to
            if retval is not None:
                return retval
            else:
                raise ParserError(
                    f"Failed to find reference with key({_val}) "
                    f"for {meta.clazz.__qualname__}.{var.name} field")

        if var.is_idref and value is not None:
            if collections.is_array(value):
               return [_get_idref(val) for val in value]
            else:
                return _get_idref(value)


        # Repeating element, recursively bind the values
        if not recursive and var.list_element and isinstance(value, list):
            assert var.factory is not None
            return var.factory(
                self.bind_value(meta, var, val, recursive=True) for val in value
            )

        # If not dict this is a text or tokens value - unless the field's
        # declared class is itself a simple-content wrapper (a model with a
        # single Text var, e.g. a VO-DML PrimitiveType specialisation such as
        # ``altURL``/``ivoid``). VO-DML JSON (and Java's serialisation)
        # writes those as a bare scalar rather than as ``{"value": ...}``.
        if not isinstance(value, dict):
            if not var.is_idref:
                text_var = self._find_text_var(var.clazz)
                if text_var is not None:
                    return self.bind_complex_type(
                        meta, var, {text_var.local_name: value}
                    )
            return self.bind_text(meta, var, value)

        keys = value.keys()
        if keys == self.context.class_type.any_keys:
            # Bind data to AnyElement dataclass
            return self.bind_dataclass(value, self.context.class_type.any_element)

        if keys == self.context.class_type.derived_keys:
            # Bind data to AnyElement dataclass
            return self.bind_derived_value(meta, var, value)

        # Bind data to a user defined dataclass
        return self.bind_complex_type(meta, var, value)

    def bind_text(self, meta: XmlMeta, var: XmlVar, value: Any) -> Any:
        """Bind text/tokens value entrypoint.

        Args:
            meta: The parent xml meta instance
            var: The xml var descriptor for the field
            value: The data value

        Returns:
            The parsed tokens or text value.
        """
        if var.is_elements:
            # Compound field we need to match the value to one of the choice elements
            check_subclass = self.context.class_type.is_model(value)
            choice = var.find_value_choice(value, check_subclass)
            if choice:
                return self.bind_text(meta, choice, value)

            if value is None:
                return value

            raise ParserError(
                f"Failed to bind '{value}' "
                f"to {meta.clazz.__qualname__}.{var.name} field"
            )

        if var.any_type or var.is_wildcard:
            # field can support any object return the value as it is
            return value

        value = converter.serialize(value)

        # Convert value according to the field types
        return ParserUtils.parse_var(
            meta=meta,
            var=var,
            config=self.config,
            value=value,
            ns_map=EMPTY_MAP,
        )

    def bind_complex_type(self, meta: XmlMeta, var: XmlVar, data: dict) -> Any:
        """Bind complex values entrypoint.

        Args:
            meta: The parent xml meta instance
            var: The xml var descriptor for the field
            data: The complex data value

        Returns:
            The parsed dataclass instance.
        """
        if var.is_clazz_union:
            # Union of dataclasses
            return self.bind_best_dataclass(data, var.types)
        if var.elements:
            # Compound field with multiple choices
            return self.bind_best_dataclass(data, var.element_types)
        if var.any_type or var.is_wildcard:
            # xs:anyType element, check all meta classes
            return self.bind_best_dataclass(data, meta.element_types)

        assert var.clazz is not None

        # VO-DML JSON tags polymorphic values with a single-key wrapper naming
        # the concrete class' Meta.utype, regardless of whether the declared
        # field type has any further subclasses.

        if _is_polymorphic(var.clazz):
            return self.bind_dataclass(*self.resolve_polymorphic(data, var.clazz))
        else:
            return self.bind_dataclass(data, var.clazz)

    def bind_derived_value(self, meta: XmlMeta, var: XmlVar, data: dict) -> Any:
        """Bind derived data entrypoint.

        The data is representation of a derived element, e.g. {
            "qname": "foo",
            "type": "my:type"
            "value": Any
        }

        The data value can be a primitive value or a complex value.

        Args:
            meta: The parent xml meta instance
            var: The xml var descriptor for the field
            data: The derived element data

        Returns:
            The parsed object.
        """
        qname = data["qname"]
        xsi_type = data["type"]
        params = data["value"]

        if var.elements:
            choice = var.find_choice(qname)
            if choice is None:
                raise ParserError(
                    f"Unable to locate compound element"
                    f" {meta.clazz.__qualname__}.{var.name}[{qname}]"
                )
            return self.bind_derived_value(meta, choice, data)

        if not isinstance(params, dict):
            # Is this scenario still possible???
            value = self.bind_text(meta, var, params)
        elif xsi_type:
            clazz: type | None = self.context.find_type(xsi_type)

            if clazz is None:
                raise ParserError(f"Unable to locate xsi:type `{xsi_type}`")

            value = self.bind_dataclass(params, clazz)
        elif var.clazz:
            value = self.bind_complex_type(meta, var, params)
        else:
            value = self.bind_best_dataclass(params, meta.element_types)

        generic = self.context.class_type.derived_element
        return generic(qname=qname, value=value, type=xsi_type)

    @classmethod
    def find_var(
        cls,
        xml_vars: list[XmlVar],
        key: str,
        value: Any,
    ) -> XmlVar | None:
        """Match the name to a xml variable.

        VO-DML JSON keys fields by their Python attribute name (``var.name``)
        rather than the XML local name, and wrapped collections are emitted
        directly under the wrapper key (no extra nesting). This matches
        against ``var.name``, ``var.local_name`` and ``var.wrapper`` to
        support both styles.

        Args:
            xml_vars: A list of xml vars
            key: A key from the loaded data
            value: The data assigned to the key

        Returns:
            One of the xml vars, if all search attributes match, None otherwise.
        """
        for var in xml_vars:
            if var.wrapper == key:
                return var

            if var.local_name == key or var.name == key:
                var_is_list = var.list_element or var.tokens
                is_array = collections.is_array(value)
                if is_array == var_is_list:
                    return var
        return None


