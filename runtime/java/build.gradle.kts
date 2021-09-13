plugins {
    java
    `maven-publish`
    id("com.github.bjornvester.xjc") version "1.6.0"
}
group = "net.ivoa.vo-dml"
version = "0.1-SNAPSHOT"


dependencies {
    xjcPlugins("net.codesup.util:jaxb2-rich-contract-plugin:2.1.0")
 //   implementation("jakarta.persistence:jakarta.persistence-api:3.0.0") // more modern, but perhaps not quite ready
    implementation("javax.persistence:javax.persistence-api:2.2")
    implementation("org.slf4j:slf4j-api:1.7.32")
    testRuntimeOnly("ch.qos.logback:logback-classic:1.2.3")
}


xjc {
    xsdDir.set(layout.projectDirectory.dir("../../xsd"))
    xsdFiles = files(xsdDir.file("vo-dml-v1.0.xsd"))
    defaultPackage.set("net.ivoa.vodml.metamodel")
    options.addAll("-Xfluent-builder",
                             "-Xmeta",
                                "-extended=y")

}

java {
    modularity.inferModulePath.set(false) // still can only build on java 1.8
    sourceCompatibility = JavaVersion.VERSION_1_8
    targetCompatibility = JavaVersion.VERSION_1_8
//    withJavadocJar()
    withSourcesJar()
}

tasks.test {
    useJUnitPlatform()
}


tasks.named("sourcesJar") //explicitly add the fact that sources jar depends on the generation.
{
    dependsOn(tasks.named("xjc"))
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