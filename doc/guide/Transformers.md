Model Transformation
====================

A VO-DML transformation is something that takes the model and expresses it in another way. The parameters that can influence how a particular transformation can occur is specified in a [binding](Binding.md).


## Documentation

The most basic form of transformation is to make [human-readable documentation](Documentation.md).

## Code Generation

The following diagram illustrates the various ways that the vo-dml tools transform the vo-dml model into other representations - The actual tool commands are shown in bold against the transformation.

```plantuml format="svg_inline"
skinparam componentStyle rectangle

artifact "VODSL Model Description" as vodsl
artifact "**VO-DML Model Description**" as vodml #lightgreen
artifact "XML Schema" as xsd
artifact "JSON Schema" as jsons
artifact "TAP Schema" as tap
artifact "Java Code" as java #Salmon
artifact "Python Code" as python #Salmon
artifact "XML Model Instance" as xml #YellowGreen
artifact "JSON Model Instance" as json #YellowGreen
artifact "RDB Model Instance" as rdb #YellowGreen


vodsl --> vodml : **vodslToVodml**
vodml --> xsd : **vodmlSchema**
vodml --> jsons : **vodmlSchema**
vodml --> tap : **vodmlSchema**
vodml --> java : **vodmlJava**
vodml --> python : **vodmlPython**

java --> xml : //serializes//
java --> json : //serializes//
java --> rdb : //stores//
python --> xml : //serializes//
python --> json : //serializes//
python --> rdb : //stores//

xml ..> xsd : valid against
json ..> jsons : valid against
rdb ..> tap : valid against
```


Here the model is transformed into source code in various languages, which can then be used to hold instances
of the data model and then [serialize](Serialization.md) in various formats - currently supported

* XML
* JSON

In addition the generated code can serialize model instances to relational databases.

The languages supported are;

* [Java](JavaCodeGeneration.md)
* [Python](PythonCodeGeneration.md)

## Schema

The models are also transformed into schema that describe the various serializations. The overall aim of the 
VO-DML tooling is to be able to exchange instances of the models between different computer languages, with 
all the source code and schema automatically generated.

The gradle task

```shell
gradle vodmlSchema
```
will generate XML, JSON and TAP schema for the model. The schema will be generated in the directory defined by the `outputSchemaDir` property (default `build/generated/sources/vodml/schema/`).

The database serialization is described in terms of a TAP schema. The specific  TAP Schema serialization is itself [defined in vodml](https://ivoa.github.io/TAPSchemaDM/). The XML serialization prefixes all of the column names with the table name and a '.' - this is done because the column names are XMLIDs and the prefix is required to ensure that they IDs are unique in the whole serialization document - The consequence of this is that when creating DDL it is expected that this table name would be removed. There is an [initial template xslt](https://github.com/ivoa/TAPSchemaDM/blob/main/src/main/resources/tap2posgresql.xsl) that will transform a tap definition into DDL for PostgreSQL - this might need adjusting for your particular environment - in particular it does not deal with DDL schema. 

The schema files are named by adjusting the suffixes in the following fashion - if the original file is called ```model.vo-dml.xml``` 

* ```model.vo-dml.xsd``` for the XML Schema
* ```model.vo-dml.json``` for the JSON Schema
* ```model.vo-dml.tap.xml``` for the TAP Schema

These schema files will automatically be included within the jar file for the model, so that instance validation can be automatically done without reference to external files.

## Transformation to VO-DML

The transformation of other data model representations to VO-DML is [discussed elsewhere](modelling/TransformingToVODML.md). 
