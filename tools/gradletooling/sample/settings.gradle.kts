
pluginManagement {
    repositories {
        mavenLocal()
        gradlePluginPortal()
        mavenCentral()
    }
    includeBuild("../gradle-plugin") //get the gradle plugin
}

// == Define locations for components ==
dependencyResolutionManagement {
    repositories {
        mavenLocal()
        mavenCentral()
    }

}
includeBuild("../../../models/ivoa")
rootProject.name="vodml-sample"
