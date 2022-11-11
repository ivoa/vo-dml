plugins {
    id("net.ivoa.vo-dml.vodmltools") version "0.3.13"
//    id ("com.diffplug.spotless") version "5.17.1"
    `maven-publish`
    id("io.github.gradle-nexus.publish-plugin") version "1.1.0"
    signing

}


repositories {
    mavenLocal() // TODO remove this when releasing - just here to pick up local vodml-runtime
    mavenCentral()
}

group = "org.javastro.ivoa.vo-dml"
version = "1.0-SNAPSHOT"

vodml {
    vodmlDir.set(file("vo-dml"))
    bindingFiles.setFrom(file("vo-dml/ivoa_base.vodml-binding.xml")
    )

}

tasks.test {
    useJUnitPlatform()
}

dependencies {
    testImplementation("org.junit.jupiter:junit-jupiter-api:5.7.1")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine:5.7.1")

    implementation("org.slf4j:slf4j-api:1.7.36")
    testRuntimeOnly("ch.qos.logback:logback-classic:1.2.3")

    testImplementation("org.apache.derby:derby:10.14.2.0")
    compileOnly("com.google.googlejavaformat:google-java-format:1.12.0")

}

//publishing - IMPL would be nice to factor this out in some way....
nexusPublishing {
    repositories {
        sonatype()
    }
}


publishing {
    publications {
        create<MavenPublication>("mavenJava") {
            from(components["java"])
            versionMapping {
                usage("java-api") {
                    fromResolutionOf("runtimeClasspath")
                }
                usage("java-runtime") {
                    fromResolutionResult()
                }
            }
            pom {
                name.set("VO-DML IVOA Base Model")
                description.set("The code generated from the IVOA base model that is included in most other models")
                url.set("https://www.ivoa.net/documents/VODML/")
                licenses {
                    license {
                        name.set("The Apache License, Version 2.0")
                        url.set("http://www.apache.org/licenses/LICENSE-2.0.txt")
                    }
                }
                developers {
                    developer {
                        id.set("pahjbo")
                        name.set("Paul Harrison")
                        email.set("paul.harrison@manchester.ac.uk")
                    }
                }
                scm {
                    connection.set("scm:git:git://github.com/ivoa/vo-dml.git")
                    developerConnection.set("scm:git:ssh://github.com/ivoa/vo-dml.git")
                    url.set("https://github.com/ivoa/vo-dml")
                }
            }
        }
    }
}

println ("java property skipSigning= " + project.hasProperty("skipSigning"))

signing {
    setRequired { !project.version.toString().endsWith("-SNAPSHOT") && !project.hasProperty("skipSigning") }

    if (!project.hasProperty("skipSigning")) {
        useGpgCmd()
        sign(publishing.publications["mavenJava"])
    }
}
//do not generate extra load on Nexus with new staging repository if signing fails
tasks.withType<io.github.gradlenexus.publishplugin.InitializeNexusStagingRepository>().configureEach{
    shouldRunAfter(tasks.withType<Sign>())
}
