//IMPL cannot get this composite build to work - have resorted to sequence of commands in github CI

//tasks.register("doAll"){
//    dependsOn(gradle.includedBuild("ivoa").task(":jar"))
//    finalizedBy(gradle.includedBuild("gradletooling").task(":vodml-sample:test"))
//    description = "builds and installs the runtime library and then runs unit tests on code generated from sample model"
//}

// would like rto do something like this
//tasks.register<GradleBuild>("doAll"){
//
//    val runtime = gradle.includedBuild("java").task(":publishToMavenLocal")
//    val base  = gradle.includedBuild("ivoa").task(":publishToMavenLocal")
//    val sample =  gradle.includedBuild("gradletooling").task(":vodml-sample:test")
//
//
//    tasks = listOf(runtime.name, base.name, sample.name)
//
//    description = "builds and installs the runtime library and then runs unit tests on code generated from sample model"
//}
