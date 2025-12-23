# Introduction

VO-DML is defined formally in an [IVOA Standard](https://www.ivoa.net/documents/VODML/index.html), however,
this guide is intended to offer practical assistance to those who want to 
use VO-DML to create data models, and then create code that can serialize those 
models to various formats. 

!!! quote "[Linus Torvalds](https://lwn.net/Articles/193245/)"
    Good programmers worry about data structures and their relationships.

The purpose of writing data models is two-fold

* It defines concepts for a particular domain in an abstract way that provides a common discourse about meanings within that domain.
* It provides a machine-readable representation that can be transformed in various ways that allow 
  instances of the model to be transported, stored and queried.

[Start Modelling](Installation.md) and learn about [model design](modelling/designIntro.md)

## Features of VO-DML tooling

* easy to install - create a dependency on this project rather than checking it out [see template](https://github.com/ivoa/DataModelTemplate)
* [model validation](modelling/Validation.md)
* auto-generation of XML, JSON and TAP Schema
* auto-generation of [Java](JavaCodeGeneration.md) and [Python](PythonCodeGeneration.md) code that [serializes](Serialization.md) to these schema.