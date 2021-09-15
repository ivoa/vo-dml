VO-DML Gradle Plugin
=====================

The gradle plugin is intended to replace all the functionality of the 
previous ant based build, but to use gradle conventions to make the configuration
easier, as well as take advantage of the dependency management features and maven repositories.

Note that the plugin is currently distributed via GitHub packages rather than via the 
gradle plugins repository because it is easier for different people to authenticate to GitHub for
deployment than in the gradle repository. If the plugin were to be distributed via gradle then
 the repository management in step 2 below would not be necessary

The general idea is that all that should be necessary to set up a new project is

1. install gradle
2. edit a `settings.gradle.kts` file to add the GitHub
```kotlin
pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
        maven {
          url = uri("https://maven.pkg.github.com/ivoa/vo-dml")
        }
    }
}

```
3. edit a `build.gradle.kts` file with reference to the plugin

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

TBC
