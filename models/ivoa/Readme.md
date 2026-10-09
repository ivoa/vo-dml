IVOA Base model
===============

This directory contains the base model and the mechanism to build code from it and publish that
code and the model.

Since the introduction of the ability to represent the JSON serialization of polymorphism in two ways - i.e. either via an enclosing object or via a property, there needs to be two separate versions of the published library. The default is to use an enclosing object (for greatest compatibility with choices made in languages other than Java) - this is the version that is published to maven central. 

The version that uses a property for the JSON serialization of polymorphism is published with an `alt` classifier. This can be done with

```shell
./gradlew clean
./gradlew publish -PuseAltBinding=true
```