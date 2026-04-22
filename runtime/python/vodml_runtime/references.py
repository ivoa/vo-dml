"""
XML ID/IDREF resolution for VO-DML pydantic models.

This module provides the Python equivalent of the Java JAXB ``@XmlID`` /
``@XmlIDREF`` mechanism.  After xsdata deserialises an XML document into
pydantic model instances, ``resolve_references`` walks the object tree,
builds a registry of all objects that carry an identifier, and replaces
every string-valued IDREF field with the actual referenced object.

The resolution uses explicit metadata emitted by the XSLT code generator
rather than runtime type introspection heuristics:

1. Referenceable objects declare ``_vodml_id_field`` (a ``ClassVar[str]``)
   naming the field that carries their identity — either a natural-key
   attribute (e.g. ``"name"``) or the surrogate ``id`` field mapped to the
   ``_id`` XML attribute.

2. Reference fields are listed in ``_vodml_refs`` (a ``ClassVar[list[str]]``)
   on each class that contains VO-DML ``<reference>`` elements.  This is
   emitted on both ``objectType`` and ``dataType`` classes.

Typical usage (called automatically by the generated ``from_xml`` override on
model-wrapper classes)::

    model = MyModelModel.from_xml(xml_bytes)
    # model.someContent[0].ref1 is now a Refa instance, not a string

Note that this file was largely AI generated - it might be over complex...
"""

#  Copyright (c) 2026. Paul Harrison, University of Manchester

from __future__ import annotations

import logging
from typing import Any

from pydantic import BaseModel

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# ID registry
# ---------------------------------------------------------------------------

class VodmlIdRegistry:
    """Maps XML ID strings to deserialised model objects."""

    def __init__(self) -> None:
        self._by_id: dict[str, Any] = {}

    def register(self, id_value: str, obj: Any) -> None:
        """Register *obj* under the given *id_value*."""
        if id_value is not None:
            self._by_id[id_value] = obj

    def resolve(self, id_value: str) -> Any | None:
        """Return the object registered for *id_value*, or ``None``."""
        return self._by_id.get(id_value)

    def __len__(self) -> int:
        return len(self._by_id)

    def __repr__(self) -> str:
        return f"VodmlIdRegistry({len(self._by_id)} entries)"


# ---------------------------------------------------------------------------
# Metadata helpers
# ---------------------------------------------------------------------------

def _find_id_field(cls: type) -> str | None:
    """Walk the MRO to find ``_vodml_id_field``.

    ``_vodml_id_field`` is a ``ClassVar[str]`` emitted by the XSLT code
    generator on every referenceable type.  It names the field that carries
    the object's XML ID — either a natural-key attribute or the surrogate
    ``id`` field.

    Because Python attribute lookup follows the MRO, a subclass that does
    not itself declare ``_vodml_id_field`` will inherit it from its parent
    (e.g. ``ReferredTo1(Refbase)`` inherits ``Refbase._vodml_id_field``).
    """
    for klass in cls.__mro__:
        field = klass.__dict__.get('_vodml_id_field')
        if field is not None:
            return field
    return None


def _collect_vodml_refs(cls: type) -> set[str]:
    """Collect all ``_vodml_refs`` entries from the class's MRO.

    Each class in the hierarchy may declare its own ``_vodml_refs`` listing
    the reference field names defined at *that* level.  This helper merges
    them all so that a subclass inherits reference metadata from its parents.
    """
    refs: set[str] = set()
    for klass in cls.__mro__:
        r = klass.__dict__.get('_vodml_refs')
        if r is not None:
            refs.update(r)
    return refs


def _get_object_id(obj: Any) -> str | None:
    """Return the XML ID string for a model object, or ``None``.

    Uses the ``_vodml_id_field`` class-level metadata emitted by the
    XSLT code generator to determine which field carries the object's
    identity.
    """
    id_field = _find_id_field(obj.__class__)
    if id_field is not None:
        val = getattr(obj, id_field, None)
        if val is not None:
            return str(val)
    return None


# ---------------------------------------------------------------------------
# Registry builder
# ---------------------------------------------------------------------------

def _build_registry_from_refs(refs_obj: Any, registry: VodmlIdRegistry) -> None:
    """Walk every list-valued field in a *Refs* container and register items."""
    if refs_obj is None:
        return
    for field_name in refs_obj.__class__.model_fields:
        value = getattr(refs_obj, field_name, None)
        if value is None:
            continue
        if isinstance(value, list):
            for item in value:
                obj_id = _get_object_id(item)
                if obj_id is not None:
                    registry.register(obj_id, item)
        elif isinstance(value, BaseModel):
            obj_id = _get_object_id(value)
            if obj_id is not None:
                registry.register(obj_id, value)


# ---------------------------------------------------------------------------
# Recursive reference resolver
# ---------------------------------------------------------------------------

def _resolve_fields(obj: Any, registry: VodmlIdRegistry) -> Any:
    """Recursively resolve string IDREFs inside *obj* to actual objects.

    Uses the ``_vodml_refs`` class metadata to identify which fields are
    VO-DML references.  For each such field, if the current value is a
    ``str``, it is looked up in the *registry* and replaced with the
    resolved object.  Non-reference fields that contain nested
    ``BaseModel`` instances are recursed into.

    Returns the (possibly mutated) *obj*.
    """
    if not isinstance(obj, BaseModel):
        return obj

    ref_fields = _collect_vodml_refs(obj.__class__)
    updates: dict[str, Any] = {}

    for field_name in obj.__class__.model_fields:
        value = getattr(obj, field_name, None)
        if value is None:
            continue

        if field_name in ref_fields:
            # --- reference field ---
            if isinstance(value, str):
                resolved = registry.resolve(value)
                if resolved is not None:
                    updates[field_name] = resolved
            elif isinstance(value, list):
                new_list = []
                changed = False
                for item in value:
                    if isinstance(item, str):
                        resolved = registry.resolve(item)
                        if resolved is not None:
                            new_list.append(resolved)
                            changed = True
                        else:
                            new_list.append(item)
                    else:
                        if isinstance(item, BaseModel):
                            _resolve_fields(item, registry)
                        new_list.append(item)
                if changed:
                    updates[field_name] = new_list
            elif isinstance(value, BaseModel):
                # Value is already an object (e.g. embedded inline rather
                # than via IDREF) — recurse in case it has nested refs.
                _resolve_fields(value, registry)
        else:
            # --- non-reference field: recurse into nested models ---
            if isinstance(value, BaseModel):
                _resolve_fields(value, registry)
            elif isinstance(value, list):
                for item in value:
                    if isinstance(item, BaseModel):
                        _resolve_fields(item, registry)

    if updates:
        for k, v in updates.items():
            object.__setattr__(obj, k, v)

    return obj


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def resolve_references(model_instance: Any) -> Any:
    """Post-deserialisation pass: replace string IDREFs with actual objects.

    This is the Python equivalent of Java's ``processReferences()`` (read
    direction).  It inspects the ``refs`` field of the model wrapper, builds
    a :class:`VodmlIdRegistry`, then recursively walks the model tree
    replacing every ``str``-valued reference field with the looked-up object.

    The resolution is driven entirely by two pieces of class-level metadata
    emitted by the XSLT code generator:

    * ``_vodml_id_field`` — names the identity field on referenceable types
    * ``_vodml_refs`` — lists the reference field names on each class

    Parameters
    ----------
    model_instance
        A top-level model wrapper (e.g. ``MyModelModel``) that has a ``refs``
        attribute containing the referenceable objects.

    Returns
    -------
    The same *model_instance*, mutated in place.
    """
    registry = VodmlIdRegistry()

    # Phase 1: build ID registry from the refs section
    refs = getattr(model_instance, 'refs', None)
    _build_registry_from_refs(refs, registry)

    if len(registry) == 0:
        return model_instance

    logger.debug("Built ID registry with %d entries, resolving references …", len(registry))

    # Phase 2: resolve IDREF strings in reference fields
    _resolve_fields(model_instance, registry)

    return model_instance

