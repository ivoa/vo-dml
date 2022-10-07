Serialization
=============

The design choices made in the serialization of the models to various formats has been driven by the capabilities
of the various libraries/standards that are applicable to the Java generated code. Other language implementations
will follow the choices that were made in order to be interoperable.

The aim of the top level container object is to contain all the referred to objects as well as the general content within
a single document. It should be noted that this is a different methodology to the way that the 
XML was produced in the previous (ant based) versions of this tooling, and as such the XML target namespaces have been changed.


## XML


The overall model object will produce xml like

```xml
<MyModel>
    <refs>
        <aref id="1000">...</aref>
        <aref id="1001">...</aref>
    </refs>
    <contentObjectType1> 
        ...
        <ref>1001</ref>
        ...
    </contentObjectType1>
    ...
</MyModel>
```

## JSON

JSON does not natively have an equivalent to the XML-ID/IDREF mechanism

## Relational Databases

