Python Pydantic Code Generation
======================

Pydantic is a Python library for data validation and settings management using Python type annotations. It provides a way to define data models with type hints and automatically validates the data against those types.

The generated pydantic code uses the [xsdata](https://xsdata.readthedocs.io/en/latest/) for XML serialization and the [VO-DML python runtime library](https://github.com/ivoa/vo-dml/tree/main/runtime/python) for JSON serialization.


## Using

The command
```shell
gradle vodmlPydanticGenerate
```
will generate python data classes in the `./build/generated/sources/vodml/python` directory by default (changeable with the `outputPythonDir` vodml setting).