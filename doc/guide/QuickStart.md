Configuring the VO-DML Gradle Plugin
===================================

Latest published version [![gradle plugin](https://img.shields.io/gradle-plugin-portal/v/net.ivoa.vo-dml.vodmltools?label=gradle%20plugin)](https://plugins.gradle.org/plugin/net.ivoa.vo-dml.vodmltools)

In general, a new data model should be started in its own git repository and configured
as below (see [ProposalDM](https://github.com/ivoa/ProposalDM) for a complete example separate from this repository). 
If starting a completely new data model then the [Template DM Project](https://github.com/ivoa/DataModelTemplate) is probably the easiest way to get going.

If adapting an existing data model repository then

1. Edit a `build.gradle.kts` file with reference to the plugin (note substitute ![latest published version](https://img.shields.io/gradle-plugin-portal/v/net.ivoa.vo-dml.vodmltools?label=latest%20published%20version) below)
```kotlin
plugins {
    id("net.ivoa.vo-dml.vodmltools") version "0.x.x"
}
```
2. create a `settings.gradle.kts` - it is possible just to copy the [template version](https://github.com/ivoa/DataModelTemplate/blob/master/settings.gradle.kts) and just edit the `rootProject.name`.
3. create the binding file for the model (see [below](#binding-files)) for more detail 

There is nothing else that needs to be done if the VO-DML files in the default place 
(see [sample build file](https://github.com/ivoa/vo-dml/tree/master/tools/gradletooling/sample/build.gradle.kts) for some more 
hints on how gradle flexibility allows finding of the files
to be configured in a variety of ways). 

If the configuration is successful then

```shell
gradle vodmlValidate
```
will attempt to validate the model and print any errors.

If the validation is successful you can produce [various derived products](Transformers.md). Developing your VO-DML model further is discussed [here](modelling/modellingIntro.md). 


## Detailed configuration

The vodml tools are all configured within a 
```kotlin
vodml {
    
}
```
section in the `build.gradle.kts` file.

The various sub-properties that can be set are

* _vodmlDir_ - the default is `src/main/vo-dml`
  ```kotlin
  vodmlDir.set(file("vo-dml"))
  ```
  will set the directory to be `vo-dml`
* _vodmlFiles_ - this is set by default to be all the `*.vo-dml.xml` files in the vodmlDir, but can be individually overridden.
* _bindingFiles_ - the files that specify the mapping details between the models and the generated code.

* _outputDocDir_ - where the generated documentation is created by the `gradle vodmlDoc` command- default `build/generated/docs/vodml/`.
* _outputSiteDir_ - where the [mkdocs](https://www.mkdocs.org) suitable model description is created by the `gradle vodmlSite` command - default `build/generated/docs/vodml-site`.
* _outputJavaDir_ - where the generated Java is created - the default is `build/generated/sources/vodml/java/` and it should not 
  be necessary to ever alter this as gradle will integrate this automatically into the various source paths.
* _outputSchemaDir_ - where the XML and JSON schema are generated to - the default is `build/generated/sources/vodml/schema/` - this is automatically included in the classpath and the output jar.
* _catalogFile_ - in general it is not necessary to set this, as the plugin will create a catalogue file automatically from the vodmlDir and vodmlFiles properties (as well as including files in any dependencies that also contain VO-DML models)
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

## Binding Files

The binding file is used to set up some properties for various functions on the model - the
most basic of which is that it provides a connection between the model name and the filename
which contains the VO-DML model.

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

The [schema](https://github.com/ivoa/vo-dml/tree/master/xsd/vo-dml-binding.xsd) for the binding file shows what elements are allowed. The [binding file for the base IVOA model](https://github.com/ivoa/vo-dml/tree/master/models/ivoa/vo-dml/ivoa_base.vodml-binding.xml)
shows extensive use of the binding features, where it is possible to ignore the automated code generation entirely and substitute
hand-written code.





