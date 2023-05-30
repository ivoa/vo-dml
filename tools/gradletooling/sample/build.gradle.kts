import net.ivoa.vodml.gradle.plugin.VodmlToVodslTask
import org.gradle.kotlin.dsl.support.classFilePathCandidatesFor
import ru.vyarus.gradle.plugin.python.PythonExtension
import ru.vyarus.gradle.plugin.python.task.PythonTask

/*
 * 
 */
plugins {
    id("net.ivoa.vo-dml.vodmltools") version "0.3.21"
//    id ("com.diffplug.spotless") version "5.17.1"
    id("ru.vyarus.use-python") version "3.0.0"

}


repositories {
    mavenLocal() // TODO remove this when releasing - just here to pick up local vodml-runtime
    mavenCentral()
}

group = "net.ivoa.vo-dml"
version = "0.2-SNAPSHOT"

vodml {
    vodmlDir.set(layout.projectDirectory.dir("../../../models/sample/test")) // do the models in place, rather than use the symbolic links in subdirs of here
// just act on one file
    vodmlFiles.setFrom(project.files (
        vodmlDir.file("../sample/vo-dml/Sample.vo-dml.xml"),
        vodmlDir.file("../filter/vo-dml/Filter.vo-dml.xml"),
        vodmlDir.file("like_coords.vo-dml.xml"),
        vodmlDir.file("lifecycleTest.vo-dml.xml"),
        vodmlDir.file("jpatest.vo-dml.xml"),
        vodmlDir.file("serializationExample.vo-dml.xml")

    ))

    bindingFiles.setFrom(
        project.files(
            layout.projectDirectory.dir("../../").asFileTree.matching (
                PatternSet().include("binding*model.xml")
            )
        )
    )
    vodslDir.set(vodmlDir) // same place for source models
}


/*
below is an example of how to create a task to do the UML XMI to VODML
*/
tasks.register("UmlToVodml", net.ivoa.vodml.gradle.plugin.XmiTask::class.java) {
    xmiScript.set("xmi2vo-dml_MD_CE_12.1.xsl") // the conversion script
    xmiFile.set(file("../../../models/ivoa/vo-dml/IVOA-v1.0_MD12.1.xml")) //the UML XMI to convert
    vodmlFile.set(file("test-creation-from-uml.vo-dml.xml")) // the output VO-DML file.
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
//    jvmArgs("--illegal-access=warn")
}

dependencies {
    implementation("org.javastro.ivoa.vo-dml:ivoa-base")
    testImplementation("org.junit.jupiter:junit-jupiter-api:5.7.1")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine:5.7.1")

    implementation("org.slf4j:slf4j-api:1.7.32")
    testRuntimeOnly("ch.qos.logback:logback-classic:1.2.3")
    testImplementation("com.h2database:h2:2.1.214") // try out h2
//    testImplementation("org.apache.derby:derby:10.14.2.0")
    compileOnly("com.google.googlejavaformat:google-java-format:1.12.0")

}

python {
    pythonBinary = "python3"
    scope = PythonExtension.Scope.VIRTUALENV
    envPath = "../../../venv"
    environment = mapOf("PYTHONPATH" to layout.buildDirectory.dir("generated/sources/vodml/python").get().asFile.absolutePath)

   pip("pytest:7.3.1")
   pip("SQLAlchemy:2.0.11")
    pip("xsdata[lxml,cli]:22.4")
    pip("pydantic:1.10.7")
}


tasks.register("pytest", PythonTask::class.java) {
    command = "src/test/python/SourceCatalogueTest.py"
 //   command = "-c \"import sys; print(sys.path)\""
 //   dependsOn("vodmlPythonGenerate")
}

