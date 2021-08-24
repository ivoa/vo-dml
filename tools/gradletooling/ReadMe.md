VO-DML Gradle Plugin
=====================

The gradle plugin is intended to replace all the functionality of the 
previous ant based build, but to use gradle conventions to make the configuration
easier, as well as take advantage of the dependency management features and maven repsositories.

The general idea is that all that should be necessary to set up a new project is

1. install gradle
2. edit a build.gradle file with reference to the plugin

```kotlin
plugins {
    id("net.ivoa.vodml-tools")
}
```

and if you have the VO-DML files in the default place (see [sample build file](./sample/build.gradle.kts) for some more hints on how that can be configured), 
there should be 3 tasks

* vodmlValidate - runs validation on the models.
* vodmlDoc - generate standard documentation.
* vodmlGenerateJava - generate java classes.

TBC
