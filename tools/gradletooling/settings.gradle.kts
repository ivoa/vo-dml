pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
    includeBuild("gradle-plugin") //get the gradle plugin
}

// == Define locations for components ==
dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }
}
rootProject.name="gradletooling"
include("sample")

project(":sample").name = "vodml-sample"
