plugins {
    `java-library`
    `maven-publish`
//    id("com.github.bjornvester.xjc") version "1.6.0"
    id("io.github.gradle-nexus.publish-plugin") version "1.3.0"
    signing
}
group = "org.javastro.ivoa.vo-dml"
version = "0.8.8"


dependencies {
//    xjcPlugins("net.codesup.util:jaxb2-rich-contract-plugin:2.1.0")
    implementation("org.xmlresolver:xmlresolver:6.0.18") // for xml catalogues - note that the apache xml-commons resolver is out of date
    implementation("jakarta.xml.bind:jakarta.xml.bind-api:4.0.0")
//    implementation("org.glassfish.jaxb:jaxb-runtime:2.3.6")
    implementation("jakarta.persistence:jakarta.persistence-api:3.1.0")
    implementation("com.fasterxml.jackson.core:jackson-databind:2.17.0")
    implementation("com.networknt:json-schema-validator:1.5.4")
    implementation("org.hibernate.orm:" +
            "hibernate-core:6.6.3.Final")
    
    implementation("org.slf4j:slf4j-api:1.7.36")
    compileOnly("org.junit.jupiter:junit-jupiter-api:5.9.2")// have put the base test classes in the runtime main - naughty, but easier to make everything work without changing dependencies


    testImplementation("org.junit.jupiter:junit-jupiter-api:5.9.2")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine:5.9.2")
    testRuntimeOnly("ch.qos.logback:logback-classic:1.4.12")
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
    toolchain {
        languageVersion = JavaLanguageVersion.of(17)
    }
    withJavadocJar()
    withSourcesJar()

}

tasks.javadoc {
    (options as StandardJavadocDocletOptions).tags("TODO","IMPL")
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
        //TODO this is a rather unsatisfactory kludge, but still seems better than the suggested JReleaser which is not really gradle friendly
        // see https://central.sonatype.org/publish/publish-portal-ossrh-staging-api/#configuration
        sonatype {
            nexusUrl.set(uri("https://ossrh-staging-api.central.sonatype.com/service/local/"))
            snapshotRepositoryUrl.set(uri("https://central.sonatype.com/repository/maven-snapshots/"))
        }
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
