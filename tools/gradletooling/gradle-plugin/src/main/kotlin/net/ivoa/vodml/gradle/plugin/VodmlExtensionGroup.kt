package net.ivoa.vodml.gradle.plugin

import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.ListProperty
import org.gradle.api.provider.Property


/*
 * Created on 02/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */

interface VodmlExtensionGroup {
    val name: String
    val vodmlDir: DirectoryProperty
    val vodmlFiles: ConfigurableFileCollection //IMPL might be nicer to use SourceSet.... e.g. https://github.com/gradle/gradle/blob/master/subprojects/plugins/src/main/java/org/gradle/api/plugins/JavaBasePlugin.java
    val outputJavaDir: DirectoryProperty
    val outputPythonDir: DirectoryProperty
    val outputDocDir: DirectoryProperty
    val outputSiteDir: DirectoryProperty
    val outputResourcesDir: DirectoryProperty
    val defaultPackage: Property<String>
    val generateEpisode: Property<Boolean>
    val bindingFiles: ConfigurableFileCollection
    val catalogFile: RegularFileProperty
    val modelsToDocument: Property<String>//use the model prefixes to specify which models have cross references in documentation (separate models with ,)
    val vodslDir :  DirectoryProperty
    val vodslFiles : ConfigurableFileCollection
//    val options: ListProperty<String>
//    val markGenerated: Property<Boolean>

}