/*
 * 
 */
plugins {
    id("net.ivoa.vodml-tools")
    id ("com.diffplug.spotless") version "5.14.2"

}


repositories {
    mavenCentral()
//    mavenLocal() // TODO remove this when releasing - just here to pick up local vodml-runtime
}

group = "net.ivoa.vo-dml"
version = "0.1-SNAPSHOT"

vodml {
    vodmlDir.set(layout.projectDirectory.dir("../../../models/")) // do the models in place, rather than use the symbolic links in subdirs of here
// just act on one file
    vodmlFiles.setFrom(project.files (
        vodmlDir.file("sample/sample/vo-dml/Sample.vo-dml.xml")
            ))

    bindingFiles.setFrom(
        project.files(
            layout.projectDirectory.dir("../../").asFileTree.matching (
                PatternSet().include("binding*model.xml")
            )
        )
    )

    catalogFile.set(project.file("../../catalog.xml"))
}

//FIXME spotless not working in compoasite project build - possibly https://github.com/diffplug/spotless/issues/860
// use to reformat the generated code nicely.
spotless {
    java {
        target(vodml.outputJavaDir.asFileTree.matching(
            PatternSet().include("**/*.java")
        ))
        googleJavaFormat("1.11.0")
    }
}

dependencies {
    implementation("net.ivoa.vo-dml:vodml-runtime:0.1-SNAPSHOT")
    implementation("com.google.googlejavaformat:google-java-format:1.11.0")

}