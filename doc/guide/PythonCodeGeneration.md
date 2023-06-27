Python Code Generation
======================
_NB The python code generation should currently be regarded as alpha quality in that it does not serialize model instances to something that is interoperable with the Java generated code. Indeed it is not yet guaranteed to be representing the VO-DML model fully._

## Using

The command
```shell
gradle vodmlPythonGenerate
```
will generate python data classes in the `./build/generated/sources/vodml/python` directory by default (changeable with the `outputPythonDir` vodml setting).

The code uses [xsdata](https://xsdata.readthedocs.io/en/latest/) for XML and JSON serialization and [SQLAlchemy](https://www.sqlalchemy.org) for the RDB serialization.

### environment

Although the code generation itself does not need python, to run any tests in the project 
relies on (https://github.com/xvik/gradle-use-python-plugin) to manage python virtualenv (i.e. https://virtualenv.pypa.io/en/latest/index.html - not all the other ones). This creates the virtualenv
in venv directory at top level - it does not seem to do that properly, so it is best to do that manually beforehand...

```bash
gradle pipInstall
```

Depends on python 3.10+

### testing

The project is set up with a single python test at the moment that can be run with

```shell
gradle pytest
```



## notes

* difficult to make xsdata and SQlAlchemy work together as they both want to use the same typing style - the generated code is using [SQLAlchemy legacy style](https://docs.sqlalchemy.org/en/20/orm/dataclasses.html#mapping-pre-existing-dataclasses-using-declarative-style-fields) to allow both libraries to work simultaneously with the same dataclasses.
* VO-DML dataTypes -> composites? https://docs.sqlalchemy.org/en/20/orm/composites.html
* with Dataclasses kw_only attributes seem the only practical route when there is inheritance, otherwise ordering the kw arguments after the others is painful in the code...