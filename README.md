VO-DML
======

This project contains the core definitions and tools associated with
[VO-DML](https://www.ivoa.net/documents/VODML/index.html) a data modelling
language.

There is a [Guide to creating models with VO-DML tooling](https://ivoa.github.io/vo-dml/)

[![PDF-Preview](https://img.shields.io/badge/VODML_WD_1.1-PDF-blue)](../../releases/download/WD-1.1-proposed/VO-DML.pdf)

The various subdirectories

* [doc](./doc)      : The IVOA standard document source and the vodml tools guide.
* [models](./models)   : The core IVOA data model along with a small example model.
* [xsd](./xsd)      : XML schemas associated with VO-DML.
* [templates](./templates): UML metamodel templates for various UML editors.
* [tools](./tools)    : All resources required to process VO-DML files. 
* [runtime](./runtime) : support code for using code generated from models in various languages



![main test](https://github.com/ivoa/vo-dml/actions/workflows/test.yml/badge.svg)
![site build](https://github.com/ivoa/vo-dml/actions/workflows/site.yml/badge.svg)
[![gradle plugin](https://img.shields.io/gradle-plugin-portal/v/net.ivoa.vo-dml.vodmltools?label=gradle%20plugin)](https://plugins.gradle.org/plugin/net.ivoa.vo-dml.vodmltools)
[![Standard Document PDF Preview generation](https://github.com/ivoa/vo-dml/actions/workflows/std.yml/badge.svg)](https://github.com/ivoa/vo-dml/actions/workflows/std.yml)

_note that this project was moved from https://volute.g-vo.org/svn/trunk/projects/dm/vo-dml/_
