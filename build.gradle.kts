tasks.register("doAll"){
    dependsOn(
        gradle.includedBuild("java").task(":publishToMavenLocal"),
        gradle.includedBuild("gradletooling").task(":vodml-sample:test")
    )

    description = "builds and installs the runtime library and then runs unit tests on code generated from sample model"
}