VO-DML Gradle Plugin
=====================

The gradle plugin is intended to replace all the functionality of the 
previous ant based build, but to use gradle conventions to make the configuration
easier, as well as take advantage of the dependency management features and maven repositories.

The general idea is that all that should be necessary to set up a new project is


1. install gradle (is not strictly necessary if you use the top level `gradlew` command - though needed if working directly in some of the sub-projects)
2. edit a `build.gradle.kts` file with reference to the plugin

```kotlin
plugins {
    id("net.ivoa.vo-dml.vodmltools")
}
```

and if you have the VO-DML files in the default place (see [sample build file](./sample/build.gradle.kts) for some more hints on how that can be configured), 
there should be 3 tasks

* vodmlValidate - runs validation on the models.
* vodmlDoc - generate standard documentation.
* vodmlGenerateJava - generate java classes.

The generated java code depends on the VO-DML java runtime library, which can be
referenced in maven with the following co-ordinates

```xml
<dependency>
  <groupId>org.javastro.ivoa.vo-dml</groupId>
  <artifactId>vodml-runtime</artifactId>
  <version>0.1</version>
</dependency>
```


## Publishing the runtime to Maven Central

The runtime is published to the `org.javastro` owned part of the maven central repository 

In the runtime directory the following will create a staging repository

```shell
gradle publishToSonatype closeSonatypeStagingRepository
```

which can then be checked and released in the https://oss.sonatype.org/ GUI.