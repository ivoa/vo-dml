Documentation
=============

## Individual files

```shell
gradle vodmlDoc 
```

will generate standard documentation into the directory `build/generated/docs/vodml/` (this can be changed with the `outputDocDir` setting)

This will produce a model diagram, latex and html formatted documentation, as well as a graphml representation of the model
that can be hand edited with [yEd](https://www.yworks.com/products/yed) for nicer looking model diagrams.

## Site

```shell
gradle vodmlSite
```

Will generate a whole static site describing the model that is intended to be
further processed with [mkdocs](https://www.mkdocs.org) tool that is configured with the [material theme](https://squidfunk.github.io/mkdocs-material/).

The site is generated at in the `build/generated/docs/vodml-site/` directory (which can be changed with the `outputSiteDir` setting).

The [DataModel Template](https://github.com/ivoa/DataModelTemplate/) has an example setup.

