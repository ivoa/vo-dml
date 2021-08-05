/*
Build for vodml gradle plugin. Written in Kotlin as that allows for better IDEA integration
 */

plugins {
    // Apply the Java Gradle plugin development plugin to add support for developing Gradle plugins
    `java-gradle-plugin`

    // Apply the Kotlin JVM plugin to add support for Kotlin.
    id("org.jetbrains.kotlin.jvm") version "1.4.31"
}

repositories {
    // Use Maven Central for resolving dependencies.
    mavenCentral()
}

//FIXME just commented this out for dev purposes as IDEA gets confused... replaced with symbolic link in resources dir
//sourceSets {
//    main {
//
//        resources {
//           // it seems that these add to the existing...
//            srcDir("$projectDir/../../")
//            include("xslt/*.xsl")
//        }
//    }
//}




dependencies {

    implementation("net.sf.saxon:Saxon-HE:10.5")
    implementation("name.dmaus.schxslt:java:3.0")

    // Align versions of all Kotlin components
    compileOnly(platform("org.jetbrains.kotlin:kotlin-bom"))

    // Use the Kotlin JDK 8 standard library.
    compileOnly("org.jetbrains.kotlin:kotlin-stdlib-jdk8")

    // Use the Kotlin test library.
    testImplementation("org.jetbrains.kotlin:kotlin-test")

    // Use the Kotlin JUnit integration.
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit")

    testImplementation("org.junit.jupiter:junit-jupiter-api:5.4.2")
    testRuntime("org.junit.jupiter:junit-jupiter-engine:5.4.2")

    //FIXME really only want to add these to the project that the plugin is used on...
    implementation("org.glassfish.jaxb:jaxb-runtime:2.3.4")
    implementation ("org.eclipse.persistence:org.eclipse.persistence.jpa:2.7.6")
    implementation ("org.eclipse.persistence:org.eclipse.persistence.moxy:2.7.6")


}


gradlePlugin {
    // Define the plugin
    val vodml by plugins.creating {
        id = "net.ivoa.vodml-tools"
        displayName = "VO-DML gradle plugin"
        version = "0.1-SNAPSHOT"
        implementationClass = "net.ivoa.vodml.gradle.plugin.VodmlGradlePlugin"
        description = "machinery for generating code and documentation from VO-DML models"

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
    systemProperty("GRADLE_BUILD_FOLDER", buildDir)
    systemProperty("GRADLE_PLUGIN_VERSION", version)
    testLogging {
        showStandardStreams = true
    }
}

tasks.check {
    // Run the functional tests as part of `check`
    dependsOn(functionalTest)
}
