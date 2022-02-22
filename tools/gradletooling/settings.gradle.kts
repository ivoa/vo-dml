
pluginManagement {
    repositories {
        mavenLocal()
        gradlePluginPortal()
        mavenCentral()
    }
    includeBuild("gradle-plugin") //get the gradle plugin
}

// == Define locations for components ==
dependencyResolutionManagement {
    repositories {
        mavenLocal()
        mavenCentral()
    }

}
rootProject.name="gradletooling"
include("sample")

project(":sample").name = "vodml-sample"
