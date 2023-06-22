Python Code Generation
======================

# environment

relies on https://github.com/xvik/gradle-use-python-plugin to manage python virtualenv (i.e. https://virtualenv.pypa.io/en/latest/index.html - not all the other ones) ends up creating the virtualenv
in venv directory at top level - it does not seem to do that properly, so it is best to do that manually beforehand...

```bash
gradle pipInstall
```

Depends on python 3.10+

*NB* this is not feature complete - there is no serialization yet implemented


## notes

* difficult to make xsdata and sqlalchemy work together - probably this legacy style https://docs.sqlalchemy.org/en/20/orm/dataclasses.html#mapping-pre-existing-dataclasses-using-declarative-style-fields best
* dataclasses -> composites? https://docs.sqlalchemy.org/en/20/orm/composites.html
* 