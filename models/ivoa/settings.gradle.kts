
pluginManagement {
    repositories {
        mavenLocal()
        gradlePluginPortal()
        mavenCentral()
    }
    includeBuild("../../tools/gradletooling/gradle-plugin") //get the gradle plugin
}

// == Define locations for components ==
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        mavenLocal()
        mavenCentral()
    }

}
includeBuild("../../runtime/java")
rootProject.name="ivoa-base"
