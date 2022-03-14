
val base = tasks.register("doBase")
{
    dependsOn(gradle.includedBuild("java").task(":publishToMavenLocal"))
    finalizedBy(gradle.includedBuild("ivoa").task(":publishToMavenLocal" ))
}

tasks.register("doAll"){
    dependsOn(base)
    finalizedBy (
        gradle.includedBuild("gradletooling").task(":vodml-sample:test")
    )
    description = "builds and installs the runtime library and then runs unit tests on code generated from sample model"
}
