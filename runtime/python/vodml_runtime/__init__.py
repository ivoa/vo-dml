"""VO-DML Python runtime support library."""

from vodml_runtime.references import resolve_references, VodmlIdRegistry
from vodml_runtime.VodmlXmlBase import _VodmlXmlBase

__all__ = ["resolve_references", "VodmlIdRegistry", "_VodmlXmlBase" ]

__version__ = "0.1.0"

