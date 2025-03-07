Model Transformation
====================

A VO-DML transformation is something that takes the model and expresses it in another way. The parameters that can influence how a particular transformation can occur is specified in a [binding](Binding.md).

# Documentation

The most basic form of transformation is to make [human-readable documentation](Documentation.md).

# Code Generation

Here the model is transformed into source code in various languages, which can then be used to hold instances
of the data model and then [serialize](Serialization.md) in various formats - currently supported

* XML
* JSON

In addition the generated code can serialize model instances to relational databases.

The languages supported are;

* [Java](JavaCodeGeneration.md)
* [Python](PythonCodeGeneration.md)

# Schema

The models are also transformed into schema that describe the various serializations. The overall aim of the 
VO-DML tooling is to be able to exchange instances of the models between different computer languages, with 
all the source code and schema automatically generated.

The gradle task

```shell
gradle vodmlSchema
```
will generate XML, JSON and TAP schema for the model. The schema will be generated in the directory defined by the `outputSchemaDir` property (default `build/generated/sources/vodml/schema/`).

The database serialization is described in terms of a TAP schema. The specific  TAP Schema serialization is itself [defined in vodml](https://github.com/ivoa/TAPSchemaDM).

The schema files are named by adjusting the suffixes in the following fashion - if the original file is called ```model.vo-dml.xml``` 

* ```model.vo-dml.xsd``` for the XML Schema
* ```model.vo-dml.json``` for the JSON Schema
* ```model.vo-dml.tap.xml``` for the TAP Schema

These schema files will automatically be included within the jar file for the model, so that instance validation can be automatically done without reference to external files.

# Transformation to VO-DML

The transformation of other data model representations to VO-DML is [discussed elsewhere](modelling/TransformingToVODML.md). 
