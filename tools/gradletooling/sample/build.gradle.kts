/*
 * 
 */
plugins {
    id("net.ivoa.vodml-tools")
}

group = "net.ivoa.vo-dml"
version = "0.1-SNAPSHOT"

vodml {
    vodmlDir.set(layout.projectDirectory.dir("../../../models/")) // do the models in place, rather than use the symbolic links in subdirs of here
// just act on one file
//    vodmlFiles.setFrom(project.files (
//        vodmlDir.file("ivoa/vo-dml/IVOA-v1.0.vo-dml.xml")
//            ))

    bindingFiles.setFrom(
        project.files(
            layout.projectDirectory.dir("../../").asFileTree.matching (
                PatternSet().include("binding*model.xml")
            )
        )
    )

    catalogFile.set(project.file("../../catalog.xml"))
}

dependencies {
    implementation("net.ivoa.vo-dml:vodml-runtime:0.1-SNAPSHOT")
}