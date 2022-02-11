/*
 * 
 */
plugins {
    id("net.ivoa.vo-dml.vodmltools") version "0.2.3"
//    id ("com.diffplug.spotless") version "5.17.1"

}


repositories {
    mavenCentral()
    mavenLocal() // TODO remove this when releasing - just here to pick up local vodml-runtime
}

group = "net.ivoa.vo-dml"
version = "0.2-SNAPSHOT"

vodml {
    vodmlDir.set(layout.projectDirectory.dir("../../../models/")) // do the models in place, rather than use the symbolic links in subdirs of here
// just act on one file
    vodmlFiles.setFrom(project.files (
        vodmlDir.file("ivoa/vo-dml/IVOA-v1.0.vo-dml.xml"),
        vodmlDir.file("sample/filter/vo-dml/Filter.vo-dml.xml"),
        vodmlDir.file("sample/test/like_coords-v1.0.vo-dml.xml"),
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

//FIXME spotless not working in composite project build - possibly https://github.com/diffplug/spotless/issues/860
// use to reformat the generated code nicely.
//spotless {
//    java {
//        target(vodml.outputJavaDir.asFileTree.matching(
//            PatternSet().include("**/*.java")
//        ))
//        googleJavaFormat("1.12.0")
//    }
//}

tasks.test {
    useJUnitPlatform()
}

dependencies {
    testImplementation("org.junit.jupiter:junit-jupiter-api:5.7.1")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine:5.7.1")

    implementation("org.slf4j:slf4j-api:1.7.32")
    testRuntimeOnly("ch.qos.logback:logback-classic:1.2.3")

    testImplementation("org.apache.derby:derby:10.14.2.0")
    compileOnly("com.google.googlejavaformat:google-java-format:1.12.0")

}
