VO-DML
======

This project contains the core definitions and tools associated with
[VO-DML](https://www.ivoa.net/documents/VODML/index.html) a data modelling
language.

The various subdirectories

* [doc](./doc)      : The IVOA standard document source.
* [models](./models)   : The core IVOA data model along with a small example model.
* [xsd](./xsd)      : XML schemas associated with VO-DML.
* [templates](./templates): UML tool metamodel templates for various tools.
* [tools](./tools)    : All resources required to process VO-DML files.
* [runtime](./runtime) : support code for using code generated from models in various languages

The most up to date way of processing VO-DML models is to use the [gradle](https://gradle.org) driven engine
for which there is more detail of how to use in the [tools/ReadMe.md](./tools/ReadMe.md)


_note that this project was moved from https://volute.g-vo.org/svn/trunk/projects/dm/vo-dml/_
