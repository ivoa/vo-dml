Developing the Gradle Plugin
============================

The work of the plugin is mainly done in the [xslt 2.0 scripts](./xslt), and the plugin 
[source](./gradletooling/gradle-plugin/src/main/kotlin/net/ivoa/vodml/gradle/plugin) is 
mainly concerned with running these.

The XSLT reads all the models and mapping files in [binding_setup.xsl](./xslt/binding_setup.xsl) and there are a series 
of useful functions that can answer model questions such as "has subtypes" defined in [common-binding.xsl](./xslt/common-binding.xsl) - Other XSLT scripts then build on these foundations.

* [vo-dml2java.xsl](./xslt/vo-dml2java.xsl) generates Java code 
* [vo-dml2python.xsl](./xslt/vo-dml2python.xsl) generates Python code
* [vo-dml2gml.xsl](./xslt/vo-dml2gml.xsl) generates the GML diagram description (part of the documentation task)
* [vo-dml2gvd.xsl](./xslt/vo-dml2gvd.xsl) generates GraphViz diagram description (part of the documentation task)
* [vo-dml2html.xsl](./xslt/vo-dml2html.xsl) generates HTML description of the model (part of the documentation task)
* [vo-dml2Latex.xsl](./xslt/vo-dml2Latex.xsl) generates LaTeX description of the model (part of the documentation task)
* [vo-dml2dsl.xsl](./xslt/vo-dml2dsl.xsl) converts VO-DML to VODSL
* 
There is a [sample](./gradletooling/sample) project that acts as a test bench for the plugin.

http://dh.obdurodon.org/xslt3.xhtml is a good summary of the new features in XSLT 3.0.

## Local testing

Testing to the plugin against the sample models can be done in the [gradletooling](./gradletooling) directory where

```shell
gradle test
```
will run all the code generation and serialization tests against the sample models.

When a new version of the plugin is being tested before release, the version numbers should be incremented and the [plugin source](./gradletooling/gradle-plugin/build.gradle.kts) and the [sample project](./gradletooling/sample/build.gradle.kts)
installed locally using

```shell
gradle :gradle-plugin:publishToMavenLocal
```

## Publishing

[@pahjbo](https://github.com/pahjbo) has the credentials for publishing the products of this repository.

### Publishing the Gradle plugin

```shell
gradle :gradle-plugin:publishplugins
```

### Publishing the Java runtime to Maven Central

The runtime is published to the `org.javastro` owned part of the maven central repository

In the top directory the following will create a staging repository

```shell
gradle :java:publishToSonatype :java:closeSonatypeStagingRepository
```

which can then be checked and released in the https://oss.sonatype.org/ GUI.

[![Maven Central](https://img.shields.io/maven-central/v/org.javastro.ivoa.vo-dml/vodml-runtime.svg?label=VODML%20Runtime)](https://search.maven.org/search?q=g:%22org.javastro.ivoa.vo-dml%22%20AND%20a:%22vodml-runtime%22)