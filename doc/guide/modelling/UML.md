UML
===

## Configuring the UML tool

In general it is necessary to configure a UML tool with the IVOA "profile" to restrict
the metamodel to that used by VO-DML.

TBC

## XMI support in the gradle tooling

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
The available conversion scripts are those in the [xslt](https://github.com/ivoa/vo-dml/tree/master/tools/xslt) directory with `xmi2vo-dml` as part of their name.
