Developing the Gradle Plugin
============================

The work of the plugin is mainly done in the [xslt 2.0 scripts](./xslt), and the plugin 
[source](./gradletooling/gradle-plugin/src/main/kotlin/net/ivoa/vodml/gradle/plugin) is 
mainly concerned with running these.

There is a [sample](./gradletooling/sample) project that acts as a test bench for the plugin.


## Publishing

[@pahjbo](https://github.com/pahjbo) has the credentials for publishing the products of this repository.

### Publishing the Gradle plugin

```shell
gradle publishPlugins
```

### Publishing the Java runtime to Maven Central

The runtime is published to the `org.javastro` owned part of the maven central repository

In the top directory the following will create a staging repository

```shell
gradle gradle :java:publishToSonatype :java:closeSonatypeStagingRepository
```

which can then be checked and released in the https://oss.sonatype.org/ GUI.

[![Maven Central](https://img.shields.io/maven-central/v/org.javastro.ivoa.vo-dml/vodml-runtime.svg?label=VODML%20Runtime)](https://search.maven.org/search?q=g:%22org.javastro.ivoa.vo-dml%22%20AND%20a:%22vodml-runtime%22)