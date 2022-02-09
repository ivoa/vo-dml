VO-DML
======

This project contains the core definitions and tools associated with
[VO-DML](https://www.ivoa.net/documents/VODML/index.html) a data modelling
language.

The various subdirectories

* [doc](./doc)      : The IVOA standard document source
* [models](./models)   : The core IVOA data model along with a small example model.
* [xsd](./xsd)      : XML schemas
* [templates](./templates): UML tool metamodel templates for various tools.
* [tools](./tools)    : All resources required to process VO-DML files
* [runtime](./runtime) : support code for using code generated from models in various languages

The "official" processing engine is driven by [ant](https://ant.apache.org) as described in the tools directory
[README](./tools/README.txt). There is an alternative [gradle](https://gradle.org) driven engine
[being developed](./tools/gradletooling), with more details [here](./tools/gradletooling/ReadMe.md)

_note that this project was moved from https://volute.g-vo.org/svn/trunk/projects/dm/vo-dml/_
