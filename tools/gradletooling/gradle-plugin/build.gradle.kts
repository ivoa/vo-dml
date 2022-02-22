
/*
Build for vodml gradle plugin. Written in Kotlin as that allows for better IDEA integration
 */

plugins {
    // Apply the Java Gradle plugin development plugin to add support for developing Gradle plugins
    `java-gradle-plugin`

    // Apply the Kotlin JVM plugin to add support for Kotlin.
    id("org.jetbrains.kotlin.jvm") version "1.4.31"
    `maven-publish`
    id("com.gradle.plugin-publish") version "0.16.0"
}

group = "net.ivoa.vo-dml"
version = "0.3.3"

repositories {
    mavenLocal() // FIXME remove this when releasing - just here to pick up local vodsl updates

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

    implementation("net.sf.saxon:Saxon-HE:10.5") // for xslt 2.0
    implementation("name.dmaus.schxslt:java:3.0") // for modern schematron
    implementation("org.xmlresolver:xmlresolver:3.0.2") // for xml catalogues - note that the apache xml-commons resolver is out of date
    implementation("org.javastro.vodsl:vodslparser:0.4.5") //standalone vodsl parser


    // Align versions of all Kotlin components
    compileOnly(platform("org.jetbrains.kotlin:kotlin-bom"))

    // Use the Kotlin JDK 8 standard library.
    compileOnly("org.jetbrains.kotlin:kotlin-stdlib-jdk8")

    // Use the Kotlin test library.
    testImplementation("org.jetbrains.kotlin:kotlin-test")

    // Use the Kotlin JUnit integration.
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit")

    testImplementation("org.junit.jupiter:junit-jupiter-api:5.7.2")
    testRuntime("org.junit.jupiter:junit-jupiter-engine:5.7.2")



}

pluginBundle {
    website = "https://www.ivoa.net/documents/VODML/"
    vcsUrl = "https://github.com/ivoa/vo-dml"
    tags = listOf("vodml", "ivoa")

 }


gradlePlugin {
    // Define the plugin
    plugins{
        create("vodmltools") {
            id = "net.ivoa.vo-dml.vodmltools"
            displayName = "VO-DML gradle plugin "
            implementationClass = "net.ivoa.vodml.gradle.plugin.VodmlGradlePlugin"
            description = "machinery for generating code and documentation from VO-DML models"

        }

    }
    isAutomatedPublishing = true

}

java {
    targetCompatibility =  JavaVersion.VERSION_1_8
}

//seem to need this hack if compiling on > jdk8 platform
val compileKotlin: org.jetbrains.kotlin.gradle.tasks.KotlinCompile by tasks
compileKotlin.kotlinOptions {
    jvmTarget = JavaVersion.VERSION_1_8.toString()
}
// end of hack

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

tasks.test {
    useJUnitPlatform()
}


publishing {

//    // Used to publish the plugin locally for testing.  To consume the plugin
//    // from here, the applying project needs to add this as a plugin repo.
//    // See https://docs.gradle.org/current/userguide/publishing_gradle_plugins.html#custom-plugin-repositories
//    //
//    // publishes to `~/.gradle/tmp/plugins`
//    //
//    // Use `gradlew publish` (instead of `gradlew publishPlugins`) to publish the
//    // plugin to this local plugin repo
//    repositories {
//        maven {
//            name = "local"
//            url = uri( "${gradle.gradleUserHomeDir}/tmp/plugins" )
//        }
//    }
}
