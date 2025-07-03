Model Design Tips
=================
 
The [formal VO-DML standard](https://www.ivoa.net/documents/VODML/) describes in some detail tha various elements that make up the VO-DML metamodel.
This documentation attempts to provide some practical guidance on how to use these elements especially in the context of the way that the VO-DML tooling
interprets and makes choices in the expression of various serializations of the models.

## ObjectType or DataType

* ObjectTypes are expressed as a table in RDB cf DataTypes are typically columns in a table.
    - In XML and JSON the differences are not so obvious
* ObjectTypes can be composed
    - This will result in foreign key references in RDBs, but in XML and JSON will usually result in child lists.

* ObjectTypes have separate identity
    - Means that they need an identifying key in RDB.
        * can use the NaturalKey constraint to use an attribute as a key
    - Though they do not necessarily need an identifying key in XML and JSON unless they are referred to.


## References
On of the key modelling tools in VO-DML is to be able to define a references to other parts of the model.
### Contained References.

### Natural Keys

The ability to set a `NaturalKey` constraint on an attribute is a new feature of VO-DML 1.1

```xml

<attribute>
    <vodml-id>Proposal.id</vodml-id>
    <name>id</name>
    <description>collection-specific identifier for the proposal</description>
    <datatype>
        <vodml-ref>ivoa:string</vodml-ref>
    </datatype>
    <multiplicity>
        <minOccurs>1</minOccurs>
        <maxOccurs>1</maxOccurs>
    </multiplicity>
    <constraint xsi:type="vo-dml:NaturalKey">
        <position>1</position>
    </constraint>
</attribute>
```
This can be used to indicate to the database serialization that the attribute should be used as the primary key rather than a surrogate primary key being generated.

The `<position>` element is intended to signify the position in a composite primary key.


#### Composite primary keys from the composition hierarchy

If the `<position>` element of the NaturalKey is set to `0` then that is used to indicate that a composite primary key should be formed from the NaturalKeys that are defined in the composition hierarchy (and it is expected that there is a NaturalKey in each element up that hierarchy) The implied extra NaturalKeys that make up the composite should not be explicitly signified in the VO-DML.

#### External references

