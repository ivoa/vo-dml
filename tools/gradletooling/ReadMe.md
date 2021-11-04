VO-DML Gradle Plugin 0.2
=====================

The gradle plugin is intended to replace all the functionality of the 
previous ant based build, but to use gradle conventions to make the configuration
easier, as well as take advantage of the dependency management features and maven repositories.

The general idea is that all that should be necessary to set up a new project is


1. install gradle (is not strictly necessary if you use the top level `gradlew` command - though needed if working directly in some of the sub-projects)
2. edit a `build.gradle.kts` file with reference to the plugin

```kotlin
plugins {
    id("net.ivoa.vo-dml.vodmltools") version "0.2"
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

## configurable plugin properties

* vodmlDir - the default is `src/main/vo-dml`
* vodmlFiles - this is set by default to be all the `*.vo-dml.xml` files in the vodmlDir, but can be indificutally set
* catalogFile - the default is `catalog.xml` and such a file is necessary even when the vodml files are in default place
  as the rest of the tooling is designed to only use the filename for inclusions and references.
```xml
<?xml version="1.0"?>
<catalog  xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog">  
   <group  prefer="system" >
       <uri
               name="IVOA-v1.0.vo-dml.xml"
               uri="src/main/vo-dml/IVOA-v1.0.vo-dml.xml"/>
   </group>
</catalog>
```
* bindingFiles - the files that specify the mapping details between the models and the generated code.
```xml
<m:mappedModels xmlns:m="http://www.ivoa.net/xml/vodml-binding/v0.9">
<!-- ========================================
This is a sample file for mapping VO-DML models to XSD or Java using the gradle tooling
 -->

<model>
<name>sample</name>
<file>Sample.vo-dml.xml</file>
<java-package>org.ivoa.dm.sample</java-package>
<xml-targetnamespace prefix="simp">http://ivoa.net/dm/models/vo-dml/xsd/sample/sample</xml-targetnamespace>
</model>
</m:mappedModels>
```
* outputDocDir - where the generated documentation is created - default `build/generated/docs/vodml/`
* outputJavaDir - where the generated Java is created - the default is `build/generated/sources/vodml/java/` and it should not 
  be necessary to ever alter this as gradle will integrate this automatically into the various source paths.

## Publishing the runtime to Maven Central

The runtime is published to the `org.javastro` owned part of the maven central repository 

In the runtime directory the following will create a staging repository

```shell
gradle publishToSonatype closeSonatypeStagingRepository
```

which can then be checked and released in the https://oss.sonatype.org/ GUI.


## Changes

* 0.2 java generation changed to cope with STC coords.