VO-DML Gradle Plugin 0.3.2
==========================

The gradle plugin is intended to replace all the functionality of the 
previous ant-based build, but to use gradle conventions to make the configuration
easier, as well as take advantage of the dependency management features and maven repositories.

Note that it is not necessary to check-out this vodml repository, but 
use the feature that gradle can automatically download dependencies. 
So, in general, a new data model should be started in its own git repository and configured
as below.


1. Install gradle (even this is not strictly necessary if you use the top level `gradlew` command - though  gradle installation is needed if working directly in some of the sub-projects)
2. Edit a `build.gradle.kts` file with reference to the plugin

```kotlin
plugins {
    id("net.ivoa.vo-dml.vodmltools") version "0.3.2"
}
```
3. create the basic catalog and binding files for the model (see below in the configuration section) 

If you have the VO-DML files in the default place (see [sample build file](gradletooling/sample/build.gradle.kts) for some more hints on how that can be configured), 
there should be 3 tasks

* vodmlValidate - runs validation on the models.
* vodmlDoc - generate standard documentation.
* vodmlGenerateJava - generate java classes. See [generated code guide](JavaCodeGeneration.md) for details of how to use the generated java code.

The generated Java code depends on the VO-DML java runtime library, which the plugin will automatically add to the
dependencies along with the necessary JAXB and JPA libraries.

## configurable plugin properties

* vodmlDir - the default is `src/main/vo-dml`
* vodmlFiles - this is set by default to be all the `*.vo-dml.xml` files in the vodmlDir, but can be individually set
* catalogFile - the default is `catalog.xml` and such a file is necessary even when the vodml files are in default place
  as the rest of the tooling is designed to use only the filename (no path) for inclusions and references.
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

## VODSL support

There is a `vodslToVodml` task that will convert models authored in [vodsl](https://github.com/pahjbo/vodsl) into standard VO-DML.

the configurable properties within the vodml extension are;

* vodslDir - the default is `src/main/vodsl`
* vodslFiles - this is set by default to be all the `*.vodsl` files in the vodslDir, but can be individually set.

the task will write the VO-DML files into the vodmlDir

## XMI support

As there are several UML tools and the XMI produced by each is slightly different,
there is not a specific XMI to VO-DML task, but rather a `net.ivoa.vodml.gradle.plugin.XmiTask`
that can be customized with the correct XSLT in the `build.gradle.kts`

```kotlin
tasks.register("UmlToVodml", net.ivoa.vodml.gradle.plugin.XmiTask::class.java) {
    xmiScript.set("xmi2vo-dml_MD_CE_12.1.xsl") // the conversion script - automatically found in the xslt directory
    xmiFile.set(file("models/ivoa/vo-dml/IVOA-v1.0_MD12.1.xml")) //the UML XMI to convert
    vodmlFile.set(file("test.vo-dml.xml")) // the output VO-DML file.
    description = "convert UML to VO-DML"
}
```


## Publishing the Java runtime to Maven Central

The runtime is published to the `org.javastro` owned part of the maven central repository 

In the runtime directory the following will create a staging repository

```shell
gradle publishToSonatype closeSonatypeStagingRepository
```

which can then be checked and released in the https://oss.sonatype.org/ GUI.


## Changes

* 0.2 java generation changed to cope with STC coords.
* 0.2.1 minor updates so that proposalDM generation works
* 0.2.2 make sure that the jpa override will work for mapped primitives - added extra attribute on the mapping
* 0.3.1 add the vodslToVodml task (0.3.0 would not publish because of SNAPSHOT dependency)
* 0.3.2 add the XmiTask type

_TODO - there is still some information in the [README.txt](./README.txt) file that should be incorporated in these instructions_