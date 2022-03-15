import org.gradle.kotlin.dsl.support.classFilePathCandidatesFor

/*
 * 
 */
plugins {
    id("net.ivoa.vo-dml.vodmltools") version "0.3.4"
//    id ("com.diffplug.spotless") version "5.17.1"

}


repositories {
    mavenLocal() // TODO remove this when releasing - just here to pick up local vodml-runtime
    mavenCentral()
}

group = "net.ivoa.vo-dml"
version = "0.2-SNAPSHOT"

vodml {
    vodmlDir.set(layout.projectDirectory.dir("../../../models/")) // do the models in place, rather than use the symbolic links in subdirs of here
// just act on one file
    vodmlFiles.setFrom(project.files (
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

}


/*
below is an example of how to create a task to do the UML XMI to VODML
*/
tasks.register("UmlToVodml", net.ivoa.vodml.gradle.plugin.XmiTask::class.java) {
    xmiScript.set("xmi2vo-dml_MD_CE_12.1.xsl") // the conversion script
    xmiFile.set(file("../../../models/ivoa/vo-dml/IVOA-v1.0_MD12.1.xml")) //the UML XMI to convert
    vodmlFile.set(file("test.vo-dml.xml")) // the output VO-DML file.
    description = "convert UML to VO-DML"
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
    implementation("org.javastro.ivoa.vo-dml:ivoa-base")
    testImplementation("org.junit.jupiter:junit-jupiter-api:5.7.1")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine:5.7.1")

    implementation("org.slf4j:slf4j-api:1.7.32")
    testRuntimeOnly("ch.qos.logback:logback-classic:1.2.3")

    testImplementation("org.apache.derby:derby:10.14.2.0")
    compileOnly("com.google.googlejavaformat:google-java-format:1.12.0")

}

