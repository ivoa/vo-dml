Serialization
=============

The design choices made in the serialization of the models to various formats has been driven by the capabilities
of the various libraries/standards that are applicable to the Java generated code. Other language implementations
will follow the choices that were made in order to be interoperable.

For the serializations (other than the relational database), the general idea is that a "natural" serialization for the model
has been chosen, in contrast to the approach of MiVOT
where the idea is that the model is coerced into a table based model - which of course is similar to the relational 
database serialization below. This "natural" serialization means that objects are enclosed within their parents to whatever depth 
is necessary. The only exception to this is that referenced objects are separated out into their own section early in the 
serialization so that they can easily be referenced.

The aim of the top level container object is to contain all the referred to objects as well as the general content within
a single document. It should be noted that this is a different methodology to the way that the 
XML was produced in the previous (ant based) versions of this tooling, and as such the XML target namespaces have been changed.


## XML

The overall model object will produce xml like

```xml
<MyModel>
    <refs>
        <aref id="1000">...</aref>
        <bref name="bid">...</bref>
    </refs>
    <contentObjectType1> 
        <bref>bid</bref>
        ...
    </contentObjectType1>
    <contentObjectType1>
        <aref>1000</aref>
        ...
    </contentObjectType1>
    ...
</MyModel>
```

## JSON

JSON does not natively have an equivalent to the XML-ID/IDREF mechanism, however, it is possible to distinguish between 
a named object as the value of a field or a string or integer literal value for the same field which could be interpreted
as a reference to the object if the data model is known.

```json
{
  "MyModel": {
    "refs": {
        "mymodel:package.refa" : [
          {"name": "a1", "val" : "aval"},
          {"name": "a2", "val" : "aval2"}
        ],
      "mymodel:package.refb" : [
        {"_id" : 1000, "val" : "aval"},
        {"_id" : 1001, "val" : "aval2"}
      ]
    }, 
    "content" : [ {
      "mymodel:package.content1" : {"zval" : "aval", "refa" : "a1"}
    },
      {
      "mymodel:package.another1" : {
        "nval" : "aval", "refb" : 1001, 
        "enc": {"foo": 23, "bar": "value"}
      }
     }
    ]
  }
}
```
In general where the type of an object cannot be inferred unambiguously from the model, then the object instance is 
created by enclosing the object as the value of a member where the member name is the UType of the object. This choice,
as opposed to for instance having a member called `type` with the UType as value, was made to avoid any potential 
clashes with members generated from the data model.

## Relational Databases
The object relational mapping has been done with the capabilities offered by JPA. The general design 
decisions that have been made for the mapping are.

* The default [inheritance strategy](https://en.wikibooks.org/wiki/Java_Persistence/Inheritance) is "JOINED" - which means that there will be a table per sub-type that has to be joined. This strategy the default as it allows for the widest application of "NOT NULL" constraints within the database, at the expense of more complex joins being required. As an alternative a "SINGLE_TABLE" strategy can be adopted, by specifying 
```xml
        <rdb inheritance-strategy="single-table"/>
```
in the binding file for the model.

* DataTypes become embedded as extra columns within the table.

Generating the actual DDL for the database does necessarily depend on some differences between vendors.
However, running the test will produce DDL.