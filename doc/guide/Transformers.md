Model Transformation
====================

A VO-DML transformation is something that takes the model and expresses it in another way.

# Documentation

The most basic form of transformation is to make [human-readable documentation](Documentation.md).

# Code Generation

Here the model is transformed into source code in various languages, which can then be used to hold instances
of the data model and then [serialize](Serialization.md) in various formats - currently supported

* XML
* JSON

The languages supported are;

* [Java](JavaCodeGeneration.md)
* Python (coming soon)

# Schema

The models are also transformed into schema that describe the various serializations. The overall aim of the 
VO-DML tooling is to be able to exchange instances of the models between different computer languages, with 
all the source code and schema automatically generated.

The gradle plugin does not currently have a task directly to generate XML and RDB schema from the models, however, this can be done
indirectly from the generated Java code as can be seen from the [Small java example](https://github.com/ivoa/vo-dml/tree/master/gradletooling/sample/src/main/java/WriteSampleSchema.java).

