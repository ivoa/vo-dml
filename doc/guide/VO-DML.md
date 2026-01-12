Quick Introduction to VO-DML
======================

The Virtual Observatory Data Modelling Language (VO-DML) is a "meta-model" i.e. a language for defining models.

The [VO-DML Standard](https://www.ivoa.net/documents/VODML/index.html) discusses in some detail the motivations for creating VO-DML which are summarized below;

* Desire to be able to create data models that were easy to re-use in other data models.
* It needed to be machine-readable and  both "vendor" and computer language neural to be able to provide the necessary interoperability.
* It should be able to express concepts that made clear where normalisation could occur in relational data models.


## VO-DML concepts

### Type System
|Type|Description|Example|
|----|-----------|--------|
|PrimitiveType|Atomic, basic values|"boolean", "integer", "real", "string"|
|Enumeration|A fixed list of named values|"filter_name (U, B, V, R, I)."|
|DataType   |Structured types that are treated as single values. They have no unique identity.|"A _Point_ (RA, Dec) or a _Quantity_ (Value + Unit)."|
|ObjectType |Complex entities with a unique identity and lifecycle.|An _Observation_, a _Source_, or a _Telescope_.|


### Relationships and Properties

VO-DML defines how these types connect to one another:

* **Attributes**: Simple properties of a type (e.g., the _name_ of a _TargetSource_).
* **References**: A pointer from one ObjectType to another without "owning" it. For example, an _Observation_ references a _TargetSource_.
* **Composition**: A "composition" relationship where an ObjectType owns a set (collection) of other objects. If the parent is deleted, the collection is deleted (e.g., a _Catalog_ contains a collection of _Entries_).
* **Semantic Concept** can be used to associate semantics to a model element - eg. stating that an attribute value must be from a particular vocabulary - e.g. the [IVOA standard vocabularies](https://ivoa.net/rdf/)

### Model Reuse and Packages
To keep models manageable, VO-DML uses:

* Model Import: A mechanism to include types from an existing standard model (e.g., importing the IVOABase data model for basic units and quantities) to ensure consistency. Note that more than one model may be imported.
* Packages: Logical groupings of related types (similar to folders or namespaces), mainly used to avoid potential naming clashes.


## Other VO-DML info

### VO-DML Tools presentations

* [Interop Nov 2021 - start of new tools packaging](https://wiki.ivoa.net/internal/IVOA/InterOpNov2021DM/VO-DML_TOOLS_PAH.pdf)
* [Interop May 2022 - intro to new VO-DML 1.1 constructs](https://wiki.ivoa.net/internal/IVOA/InterOpApr2022DM/VO-DML_TOOLS_Update_PAH.pdf)
* [Interop Oct 2022 - serialization and Python cocde generation](https://wiki.ivoa.net/internal/IVOA/InterOpOct2022DM/VO-DML_TOOLS_Update2_PAH.pdf)
* [Interop May 2023 - VO-DML Tools demo](https://wiki.ivoa.net/internal/IVOA/IntropMay3023DM/VO-DML_TOOLS_DEMO_PAH.pdf)


### VO-DML 1.1 presentations

* [Interop Nov 2024](https://wiki.ivoa.net/internal/IVOA/InterOpNov2024DM/VO-DML_Extensions2_PAH.pdf)








