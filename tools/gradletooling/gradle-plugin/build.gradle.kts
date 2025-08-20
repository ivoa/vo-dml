
/*
Build for vodml gradle plugin. Written in Kotlin as that allows for better IDEA integration
 */

plugins {
    // Apply the Java Gradle plugin development plugin to add support for developing Gradle plugins
    `java-gradle-plugin`
    // Apply the Kotlin JVM plugin to add support for Kotlin.
    kotlin("jvm") version "2.0.0"
    `maven-publish`
    id("com.gradle.plugin-publish") version "1.1.0"
}

group = "net.ivoa.vo-dml"
version = "0.5.28"

repositories {
    mavenLocal() // FIXME remove this when releasing - just here to pick up local vodsl updates

    // Use Maven Central for resolving dependencies.
    mavenCentral()
}





dependencies {
    implementation("org.javastro.ivoa.vo-dml:vodml-runtime:0.8.8")
    implementation("net.sf.saxon:Saxon-HE:12.5") // for xslt 3.0
    implementation("name.dmaus.schxslt:java:3.1.1") // for modern schematron
    implementation("name.dmaus.schxslt:schxslt:1.10") // force to use more updated schematron than the java wrapper naturally uses -
    implementation("org.xmlresolver:xmlresolver:6.0.18") // for xml catalogues - note that the apache xml-commons resolver is out of date
    implementation("org.javastro.vodsl:vodslparser:0.4.9") //standalone vodsl parser
    implementation("com.fasterxml.jackson.dataformat:jackson-dataformat-yaml:2.14.2")



    // Use the Kotlin test library.
    testImplementation("org.jetbrains.kotlin:kotlin-test")

    // Use the Kotlin JUnit integration.
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit5")

    testImplementation("org.junit.jupiter:junit-jupiter-api:5.7.2")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine:5.7.2")

    implementation("org.slf4j:slf4j-api:2.0.9")
    testRuntimeOnly("ch.qos.logback:logback-classic:1.4.12")

}



gradlePlugin {
    website.set("https://www.ivoa.net/documents/VODML/")
    vcsUrl.set("https://github.com/ivoa/vo-dml")

    // Define the plugin
    plugins{
        create("vodmltools") {
            id = "net.ivoa.vo-dml.vodmltools"
            displayName = "VO-DML gradle plugin "
            implementationClass = "net.ivoa.vodml.gradle.plugin.VodmlGradlePlugin"
            description = "machinery for generating code and documentation from VO-DML models"
            tags.set(listOf("vodml", "ivoa"))
        }

    }
    isAutomatedPublishing = true

}

java {
    toolchain {
        languageVersion =JavaLanguageVersion.of(17)
    }
}


sourceSets {
    main {
        // slightly complex way of adding the xslt and xsd directories to resources (they are at different levels)
        resources {
            setSrcDirs(listOf(layout.projectDirectory.dir("../../"),layout.projectDirectory.dir("../../..")))
            setIncludes(listOf("xslt/**","xsd/**"))
        }
    }
}

// Add a source set for the functional test suite
val functionalTestSourceSet = sourceSets.create("functionalTest") {
}

gradlePlugin.testSourceSets(functionalTestSourceSet)
configurations["functionalTestImplementation"].extendsFrom(configurations["testImplementation"])

// Add a task to run the functional tests
val functionalTest by tasks.registering(Test::class) {
    testClassesDirs = functionalTestSourceSet.output.classesDirs
    classpath = functionalTestSourceSet.runtimeClasspath
}

tasks.withType<Test>().configureEach {
    useJUnitPlatform()
    systemProperty("GRADLE_ROOT_FOLDER", projectDir.absolutePath)
    systemProperty("GRADLE_BUILD_FOLDER", layout.buildDirectory.asFile.get().absolutePath)
    systemProperty("GRADLE_PLUGIN_VERSION", version)
    testLogging {
        showStandardStreams = true
    }
}

//disabling tests below - think that there are Java 8/11 problems TODO reinstate tests

tasks.check {
    // Run the functional tests as part of `check`
    //dependsOn(functionalTest)
}


tasks.test {
    useJUnitPlatform()
   // exclude("**")
}

