plugins {
    `java-library`
    `maven-publish`
//    id("com.github.bjornvester.xjc") version "1.6.0"
    id("io.github.gradle-nexus.publish-plugin") version "1.1.0"
    signing
}
group = "org.javastro.ivoa.vo-dml"
version = "0.4.1"


dependencies {
//    xjcPlugins("net.codesup.util:jaxb2-rich-contract-plugin:2.1.0")
 //   implementation("jakarta.persistence:jakarta.persistence-api:3.0.0") // more modern, but perhaps not quite ready
    implementation("javax.xml.bind:jaxb-api:2.3.1")
//    implementation("org.glassfish.jaxb:jaxb-runtime:2.3.6")
    implementation("javax.persistence:javax.persistence-api:2.2")
    implementation("com.fasterxml.jackson.core:jackson-databind:2.14.2")
    implementation("org.hibernate:hibernate-core:5.6.5.Final")
    
    implementation("org.slf4j:slf4j-api:1.7.36")
    api("org.javastro:jaxbjpa-utils:0.1.2")
    compileOnly("org.junit.jupiter:junit-jupiter-api:5.7.1")// have put the base test classes in the runtime main - naughty, but easier to make everything work without changing dependencies


    testImplementation("org.junit.jupiter:junit-jupiter-api:5.7.1")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine:5.7.1")
    testRuntimeOnly("ch.qos.logback:logback-classic:1.2.3")
}


//xjc {
//    xsdDir.set(layout.projectDirectory.dir("../../xsd"))
//    xsdFiles = files(xsdDir.file("vo-dml-v1.0.xsd"))
//    defaultPackage.set("net.ivoa.vodml.metamodel")
//    options.addAll("-Xfluent-builder",
//                             "-Xmeta",
//                                "-extended=y")
//
//}

java {
//    modularity.inferModulePath.set(false) // still can only build on java 1.8
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
    withJavadocJar()
    withSourcesJar()
}

tasks.test {
    useJUnitPlatform()
}



tasks.named("sourcesJar") //explicitly add the fact that sources jar depends on the generation.
{
 //    dependsOn(tasks.named("xjc"))
}

//publishing
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
        }
    }
}
// just in case we manage to create more than one publication for test classes
publishing.publications.withType(MavenPublication::class.java).forEach { publication ->
    with(publication.pom) {
        name.set("VO-DML Runtime")
        description.set("Library needed as dependency for java code generated from VO-DML")
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
println ("java property skipSigning= " + project.hasProperty("skipSigning"))
repositories {
    mavenCentral()
}

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
