/*
this is an empty umbrella build to include the various component builds
 */

includeBuild("runtime/java") //fixed code needed by the generated code for java
includeBuild("models/ivoa") // the ivoa base model
includeBuild("tools/gradletooling") //gradle plugin
