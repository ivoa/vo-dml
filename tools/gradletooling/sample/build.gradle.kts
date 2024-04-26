import net.ivoa.vodml.gradle.plugin.VodmlToVodslTask
import ru.vyarus.gradle.plugin.python.PythonExtension
import ru.vyarus.gradle.plugin.python.task.PythonTask

/*
 * 
 */
plugins {
    id("net.ivoa.vo-dml.vodmltools") version "0.5.0"
    id("com.diffplug.spotless") version "6.25.0"
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
    outputDocDir.set(layout.projectDirectory.dir("docs"))
    outputSiteDir.set(outputDocDir.dir("generated"))
    outputSchemaDir.set(outputDocDir.dir("schema"))
    vodslDir.set(vodmlDir) // same place for source models
    modelsToDocument.set("sample,filter,coords,jpatest,lifecycleTest")
    outputPythonDir.set(layout.projectDirectory.dir("pythontest/generated"))
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
    testImplementation("org.junit.jupiter:junit-jupiter:5.9.2")
    testImplementation("com.networknt:json-schema-validator:1.4.0")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
    implementation("org.slf4j:slf4j-api:2.0.9")
    testRuntimeOnly("ch.qos.logback:logback-classic:1.4.7")
    testImplementation("com.h2database:h2:2.1.214") // try out h2
//    testImplementation("org.apache.derby:derby:10.14.2.0")
    compileOnly("com.google.googlejavaformat:google-java-format:1.22.0")

}

python {
    pythonBinary = "python3"
    scope = PythonExtension.Scope.VIRTUALENV
    envPath = "../../../venv"
    environment = mapOf("PYTHONPATH" to layout.projectDirectory.dir("pythontest/generated").asFile.absolutePath
                        + ":" + layout.projectDirectory.dir("../../../runtime/python").asFile.absolutePath
//                     +":"+layout.projectDirectory.dir("../../../models/ivoa/build/generated/sources/vodml/python").asFile.absolutePath
    )

   pip("pytest:7.3.1")
   pip("SQLAlchemy:2.0.25")
    pip("xsdata[lxml,cli]:24.1")
    pip("pydantic:1.10.9")
}



tasks.register("tpath") {
    group = "Other"
    description = "looking at various paths"

dependsOn("vodmlJavaGenerate")
    doLast{

        println(sourceSets.main.get().java.sourceDirectories.asPath)
        println(sourceSets.main.get().resources.sourceDirectories.asPath)
        println(sourceSets.main.get().output.classesDirs.asPath)
        println(sourceSets.test.get().resources.sourceDirectories.asPath)

        sourceSets.test.get().compileClasspath.files.forEach{
            println(it.path)
        }
        SourceSet.TEST_SOURCE_SET_NAME

    }
}

//TODO
configure<com.diffplug.gradle.spotless.SpotlessExtension> {
    // optional: limit format enforcement to just the files changed by this feature branch
   // ratchetFrom 'origin/main'


    java {
        // don't need to set target, it is inferred from java
        target("build/generated/sources/vodml/java/**/*.java")
        // apply a specific flavor of google-java-format
        googleJavaFormat("1.22.0").reflowLongStrings().skipJavadocFormatting()
        // fix formatting of type annotations
        formatAnnotations()

    }
}

tasks.register("pytest", PythonTask::class.java) {
    command = "pythontest/src/SourceCatalogueTest.py"
//    command = "-c \"import sys; print(sys.path)\""
    dependsOn("vodmlPythonGenerate")
}

tasks.register<Exec>("siteNav")
{
    commandLine("yq", "eval",  "(.nav.[]|select(has(\"AutoGenerated Documentation\"))|.[\"AutoGenerated Documentation\"]) += load(\"allnav.yml\")", "mkdocs_template.yml")
    standardOutput = file("mkdocs.yml").outputStream()
    dependsOn("vodmlSite")
}
tasks.register<Exec>("testSite"){
    commandLine("mkdocs", "serve")
    dependsOn("siteNav")
}