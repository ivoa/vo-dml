Model Validation
================

A model can be validated with the 

```shell
gradle vodmlValidate
```

command, and clearly if there are no errors then the model is unquestionably valid. However, if there are validation messages it does not necessarily mean that the model is definitely bad - The meaning of messages is discussed in more detail below. When publishing a model that has messages then it is necessary in the accompanying documentation to make clear what actions and choices have been made in mitigation of each of the messages (sometimes a complete "override" might be justified by the use of a custom type mapping in [binding](../Binding.md)).

## Validation Messages

Validation is done using schematron, which although quite powerful in its ability to detect patterns in the VO-DML, is rather limited in the way that messages can be displayed. This can cause some issues with interpretation of the messages, which this guide aims to clarify.

The validation messages can be divided into two categories:

* **fatal** - must be corrected
* **non-fatal** - need some mitigation

### Fatal

Fatal validation errors must be corrected before the model can be considered valid. These typically indicate structural problems that violate the VO-DML specification.

#### Model Imports Failed

**Pattern:** `imports_succeeded`

All model imports specified in the VO-DML document must successfully load. This error occurs when:
- The imported model file cannot be found or opened
- The imported model contains XML errors

**Related to standard:** Section 2 (Model Imports) - All referenced models must be available and well-formed.

**Resolution:** Ensure that all imported models are available at the specified URL or file location and that they are valid VO-DML documents.

#### Remote Model Import Prefix Mismatch

**Pattern:** `RemoteModelImport`

When a vodml-ref uses a prefix that is not the current model's name, there must be a corresponding import statement that declares the prefixed model. Additionally, the imported model's name and version must match what is declared in the import statement.

**Related to standard:** Section 2.2 (Model References and Imports) - Model prefixes must correspond to imported model names.

**Resolution:** 
1. Add an import statement for any referenced remote models
2. Ensure the imported model's name and version match the import declaration
3. Verify that the import URL points to the correct model file

#### Non-Unique vodml-id

**Pattern:** `Unique_vodml-id`

Every vodml-id in a model (except for the model itself) must be globally unique within that model.

**Related to standard:** Section 3.3 (Object Identification) - vodml-id must uniquely identify an element.

**Resolution:** Rename one or both of the conflicting elements to have unique identifiers. Use the standard dot-separated format based on the element's package and name hierarchy.

#### Invalid vodml-id Form

**Pattern:** `vodml-id_form`

The vodml-id must follow the standard form, which is the dot-separated hierarchical path of ancestor package/type names. For example, an attribute named `distance` in dataType `Coordinate` in package `coord` should have vodml-id `coord.Coordinate.distance`.

**Related to standard:** Section 3.3 (Object Identification) - vodml-id should follow a consistent hierarchical naming convention.

**Resolution:** Update the vodml-id to match the standard form. The error message will indicate what the expected form should be.

#### Non-Unique Member Names

**Pattern:** `Unique_name`

Within a single type (objectType or dataType), all member names (attributes, references, and compositions) must be unique.

**Related to standard:** Section 3.4 (Type Definitions) - Members of a type must have distinct names.

**Resolution:** Rename the conflicting members to have unique names within their containing type.

#### Multiple Inheritance

**Pattern:** `Single_Inheritance`

VO-DML supports only single inheritance. Each type can extend at most one other type.

**Related to standard:** Section 4 (Inheritance) - VO-DML uses single inheritance model.

**Resolution:** Refactor your type hierarchy to use single inheritance. Consider using composition or interfaces to achieve the desired behaviour.

#### Invalid Attribute Type

**Pattern:** `vodml-refs-check` (attributes)

Attributes must have datatypes (primitiveType, dataType, or enumeration). They cannot be objectTypes.

**Related to standard:** Section 3.4.1 (Attributes) - Attributes must be value types, not entities.

**Resolution:** Change the attribute's datatype to a valid value type, or convert it to a composition or reference if it should reference an object.

#### Invalid Reference Type

**Pattern:** `vodml-refs-check` (references)

References must have objectType as their datatype. They cannot be primitiveTypes, dataTypes, or enumerations.

**Related to standard:** Section 3.4.2 (References) - References must point to object types.

**Resolution:** Change the reference's datatype to an objectType, or convert it to an attribute if it should store a value.

#### Invalid Composition Type

**Pattern:** `vodml-refs-check` (compositions)

Compositions must have objectType as their datatype. They cannot be primitiveTypes, dataTypes, or enumerations.

**Related to standard:** Section 3.4.3 (Compositions) - Compositions contain object types.

**Resolution:** Change the composition's datatype to an objectType.

#### Invalid Supertype for ObjectType

**Pattern:** `vodml-refs-check` (objectType/extends)

When an objectType extends another type, the parent must also be an objectType.

**Related to standard:** Section 4 (Inheritance) - objectTypes can only inherit from other objectTypes.

**Resolution:** Ensure the extends relation points to an objectType, not a dataType or other element type.

#### Invalid Supertype for DataType

**Pattern:** `vodml-refs-check` (dataType/extends)

When a dataType extends another type, the parent must also be a dataType.

**Related to standard:** Section 4 (Inheritance) - dataTypes can only inherit from other dataTypes.

**Resolution:** Ensure the extends relation points to a dataType, not an objectType or other element type.

#### Invalid Attribute Multiplicity

**Pattern:** `vodml-refs-check` (attribute/multiplicity)

Attributes of dataType have special multiplicity constraints:
- If the datatype is a dataType (not primitiveType or enumeration), maxOccurs must be 1
- primitiveType and enumeration attributes can have multiplicity concepts but this is discouraged

**Related to standard:** Section 3.4.1 (Attributes) - Complex type attributes cannot be arrays.

**Resolution:** Either reduce maxOccurs to 1 for dataType attributes, or use a primitive type / enumeration.

#### Invalid SubsettedRole Constraint

**Pattern:** `constraint[@xsi:type='vo-dml:SubsettedRole']`

SubsettedRole constraints must reference existing roles and datatypes.

**Related to standard:** Section 5 (Constraints) - SubsettedRole constraints must be well-formed.

**Resolution:** Verify that both the role and datatype references in the constraint exist in the model.

### Non-Fatal

Non-fatal validation warnings indicate issues that may need mitigation but do not prevent the model from being used. Often these represent design choices that may have implications but are not structural violations.

#### Multiple Composition Targets

**Pattern:** `Unique_composition`

A type is used as the target of a composition relation in multiple different container types. While this is technically valid, it can have implications for object lifetime and garbage collection, as the contained object may appear in multiple places.

**Related to standard:** Section 3.4.3 (Compositions) - Note on object containment and lifecycle.

**Mitigation:** Document the shared containment relationship and ensure that application code is aware that the composed object may be referenced from multiple containers. This can affect how the object's lifecycle is managed.

#### Unexpected Attribute Multiplicity

**Pattern:** `vodml-refs-check` (attribute/multiplicity, warning)

Attributes of primitive types or enumerations with multiplicity constraints (minOccurs or maxOccurs != 1) are strongly discouraged, though technically supported.

**Related to standard:** Section 3.4.1 (Attributes) - Attributes are typically scalar values.

**Mitigation:** Consider whether a composition or reference would be more appropriate for multi-valued associations. Document the use of array-valued primitive attributes if this pattern is intentionally used.

#### Reference to Composed Type in Different Hierarchy

**Pattern:** `vodml-refs-check` (reference, warn)

A reference points to an objectType that is structured in a different composition hierarchy from the containing type. This can create lifecycle implications, as the referenced object could disappear independently if its container is deleted.

**Related to standard:** Section 3.4.2 (References) and Section 3.4.3 (Compositions) - Interaction of references and composition hierarchies.

**Mitigation:** Document this design choice and ensure that application code handles the potential for "dangling references" where the referenced object may no longer exist. Consider whether a stronger containment relationship (composition) would be more appropriate.
