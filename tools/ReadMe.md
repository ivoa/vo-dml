Using the VO-DML Gradle Plugin
===================================

Latest published version ![gradle plugin](https://img.shields.io/gradle-plugin-portal/v/net.ivoa.vo-dml.vodmltools?label=gradle%20plugin)

The aim of this plugin is to process VO-DML models to produce documentation and source code that
can contain instances the model and has the capability of serialising instances of the model to/from XML,JSON and 
relational databases.

The gradle plugin is intended to replace all the functionality of the 
previous ant-based build, but to use gradle conventions to make the configuration
easier, as well as take advantage of the dependency management features and maven repositories.

Note that it is not necessary to check-out this vodml repository as the plugin will be downloaded automatically from the gradle repository. 
So, in general, a new data model should be started in its own git repository and configured
as below.


1. [Install gradle](https://gradle.org/install/) and run `gradle init` and make choices for a library written in java (with a Kotlin build script DSL).
2. Edit a `build.gradle.kts` file with reference to the plugin (note substitute ![latest published version](https://img.shields.io/gradle-plugin-portal/v/net.ivoa.vo-dml.vodmltools?label=latest%20published%20version) below)

```kotlin
plugins {
    id("net.ivoa.vo-dml.vodmltools") version "0.x.x"
}
```
3. create the  binding files for the model (see below in the configuration section) 

There is nothing else that needs to be done if the VO-DML files in the default place 
(see [sample build file](gradletooling/sample/build.gradle.kts) for some more 
hints on how gradle flexibility allows finding of the files
to be configured in a variety of ways). 

There are 3 associated tasks

* vodmlValidate - runs validation on the models.
* vodmlDoc - generate standard documentation. This will produce a model diagram, latex and html formatted documentation, as well as a graphml representation of the model 
  that can be hand edited with https://www.yworks.com/products/yed for nicer looking model diagrams.
* vodmlJavaGenerate - generate java classes. See [generated code guide](JavaCodeGeneration.md) for details of how to use the generated java code to serialize instances to XML and RDB.


## configurable plugin properties

* vodmlDir - the default is `src/main/vo-dml`
* vodmlFiles - this is set by default to be all the `*.vo-dml.xml` files in the vodmlDir, but can be individually set
* bindingFiles - the files that specify the mapping details between the models and the generated code.
```xml
<m:mappedModels xmlns:m="http://www.ivoa.net/xml/vodml-binding/v0.9.1">
<!-- ========================================
This is a minimal sample file for mapping VO-DML models to XSD or Java using the gradle tooling
 -->

<model>
<name>sample</name>
<file>Sample.vo-dml.xml</file>
<java-package>org.ivoa.dm.sample</java-package>
<xml-targetnamespace prefix="simp" schemaFilename="simpleModel.xsd">http://ivoa.net/dm/models/vo-dml/xsd/sample/sample</xml-targetnamespace>
</model>
</m:mappedModels>
```

The [schema](../xsd/vo-dml-binding.xsd) for the binding file shows what elements are allowed. The [binding file for the base IVOA model](../models/ivoa/vo-dml/ivoa_base.vodml-binding.xml)
shows extensive use of the binding features, where it is possible to ignore the automated code generation entirely and substitute
hand-written code.

* outputDocDir - where the generated documentation is created - default `build/generated/docs/vodml/`
* outputJavaDir - where the generated Java is created - the default is `build/generated/sources/vodml/java/` and it should not 
  be necessary to ever alter this as gradle will integrate this automatically into the various source paths.
* catalogFile - in general it is not necessary to set this, as the plugin will create a catalogue file automatically from the vodmlDir and vodmlFiles properties (as well as including files in any dependencies that also contain VO-DML models)
  A catalogue file is necessary as the rest of the tooling is designed to use only the filename (no path) for inclusions and references.
  If it is desired to create a file manually for a special purpose, then the file should have the format as below - it should be noted that all references to model files will have to be specified if this is done.
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

## VODSL support

There is a `vodslToVodml` task that will convert models authored in [vodsl](https://github.com/pahjbo/vodsl) into standard VO-DML.

the configurable properties within the vodml extension are;

* vodslDir - the default is `src/main/vodsl`
* vodslFiles - this is set by default to be all the `*.vodsl` files in the vodslDir, but can be individually set.

the task will write the VO-DML files into the `vodmlDir`

### Creating VODSL from existing VO-DML

If it is desired to create VODSL from some existing VO-DML then there is a special task that can be run from the
commandline with arguments (i.e. does not have to be configured in the `build.gradle` file as it would not be a repeated part of the workflow)
The task has the `--dml` parameter to indicate the input VO-DML file and the `--dsl` parameter to indicate the output VODSL file.

```shell
gradle vodmlToVodsl --dml=../../../models/sample/sample/vo-dml/Sample.vo-dml.xml --dsl=test.vodsl 
```

## XMI support

As there are several UML tools and the XMI produced by each is slightly different,
there is not a specific XMI to VO-DML task, but rather a base `net.ivoa.vodml.gradle.plugin.XmiTask`
that can be customized with the correct XSLT in the `build.gradle.kts`

```kotlin
tasks.register("UmlToVodml", net.ivoa.vodml.gradle.plugin.XmiTask::class.java) {
    xmiScript.set("xmi2vo-dml_MD_CE_12.1.xsl") // the conversion script - automatically found in the xslt directory
    xmiFile.set(file("models/ivoa/vo-dml/IVOA-v1.0_MD12.1.xml")) //the UML XMI to convert
    vodmlFile.set(file("test.vo-dml.xml")) // the output VO-DML file.
    description = "convert UML to VO-DML"
}
```
The available conversion scripts are those in the [xslt](./xslt) directory with `xmi2vo-dml` as part of their name.

## Schema
The serializations that are implemented in the generated code are discussed in more detail [here](./Serialization.md)

The gradle plugin does not currently have a task directly to generate XML and RDB schema from the models, however, this can be done
indirectly from the generated Java code as can be seen from the [Small java example](./gradletooling/sample/src/main/java/WriteSampleSchema.java).

## Changes

* 0.2 java generation changed to cope with STC coords.
* 0.2.1 minor updates so that proposalDM generation works
* 0.2.2 make sure that the jpa override will work for mapped primitives - added extra attribute on the mapping
* 0.3.1 add the vodslToVodml task (0.3.0 would not publish because of SNAPSHOT dependency)
* 0.3.2 add the XmiTask type
* 0.3.3 bugfix for html document generation
* 0.3.4 the plugin now saves VO-DML and binding files to the created jar and then uses them if they are in dependency tree.
* 0.3.5 better working in the inherited data-model case.
* 0.3.6 JPA EntityGraphs
* 0.3.7 To VODSL task added
* 0.3.8 Add schema generation via the generated Java code.
* 0.3.9 Add JSON serialization.
* 0.3.10 Add possibility to do use "SingleTable" inheritance strategy for RDB schema
* 0.3.11 Add XSD to VODSL task.


## Information for [developers of the plugin itself](./Developing.md)
