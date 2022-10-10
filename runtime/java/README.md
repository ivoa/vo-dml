Java VODML Runtime library
=========================

This is a library of code that is needed at runtime by every generated
model - if using the gradle plugin then this library will be automatically added
to the classpath - however, when using the generated model in another context it
will be necessary to add it as an explicit dependency.

The library is published to maven central as [![vodml-runtime](https://img.shields.io/maven-central/v/org.javastro.ivoa.vo-dml/vodml-runtime.svg?label=vodml-runtime)](https://search.maven.org/artifact/org.javastro.ivoa.vo-dml/vodml-runtime/)