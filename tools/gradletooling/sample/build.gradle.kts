/*
 * 
 */
plugins {
    id("net.ivoa.vodml-tools")
    id ("com.diffplug.spotless") version "5.14.2"

}


repositories {
    mavenCentral()
    mavenLocal() // TODO remove this when releasing - just here to pick up local vodml-runtime
}

group = "net.ivoa.vo-dml"
version = "0.1-SNAPSHOT"

vodml {
    vodmlDir.set(layout.projectDirectory.dir("../../../models/")) // do the models in place, rather than use the symbolic links in subdirs of here
// just act on one file
    vodmlFiles.setFrom(project.files (
        vodmlDir.file("ivoa/vo-dml/IVOA-v1.0.vo-dml.xml"),
        vodmlDir.file("sample/filter/vo-dml/Filter.vo-dml.xml"),
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

tasks.test {
    useJUnitPlatform()
}

dependencies {
    implementation("net.ivoa.vo-dml:vodml-runtime:0.1-SNAPSHOT")
    implementation("org.javastro:ivoa-entities:0.9.3-SNAPSHOT")
    testImplementation("org.junit.jupiter:junit-jupiter-api:5.4.2")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine:5.4.2")
    testRuntimeOnly("ch.qos.logback:logback-classic:1.2.3")
}