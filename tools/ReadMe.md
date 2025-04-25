VO-DML Tools
============

There are two alternative ways to run the VO-DML tools

* via a [Gradle](https://gradle.org) plugin (source in the [gradletooling](./gradletooling) directory) 
* via the python vodmltools package (source in [pythontooling](./pythontooling) directory)

In both cases it is expected that the use will be via setting up a separate project that imports the necessary plugin/package.

The gradle tooling is far more mature than the python tooling at the moment.

In both cases the tooling sets up an appropriate environment to run the tooling business logic which is expressed in [XSLT 2](./xslt)

## Gradle Plugin tooling


Latest published version [![gradle plugin](https://img.shields.io/gradle-plugin-portal/v/net.ivoa.vo-dml.vodmltools?label=gradle%20plugin)](https://plugins.gradle.org/plugin/net.ivoa.vo-dml.vodmltools)

```kotlin
plugins {
    id("net.ivoa.vo-dml.vodmltools") version "0.x.x"
}
```

See [detailed instructions for usege](https://ivoa.github.io/vo-dml/QuickStart/)

Information for [developers of the plugin itself](./Developing.md)

[Change Log](./ChangeLog.md)


## Python tooling

_Still under construction_

```shell
pip install vodmltools
```