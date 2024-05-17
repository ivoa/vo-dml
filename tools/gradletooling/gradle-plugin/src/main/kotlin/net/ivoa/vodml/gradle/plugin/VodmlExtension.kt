package net.ivoa.vodml.gradle.plugin

import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.ProjectLayout
import org.gradle.api.model.ObjectFactory
import org.gradle.api.provider.Property
import javax.inject.Inject


/*
 * Created on 02/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */

open class VodmlExtension @Inject constructor(objects: ObjectFactory, layout: ProjectLayout): VodmlExtensionGroup {
    override val name = "Defaults"
    override val vodmlDir = objects.directoryProperty()
    override val vodmlFiles = objects.fileCollection()
    override val outputJavaDir = objects.directoryProperty()
    override val outputPythonDir = objects.directoryProperty()
    override val outputDocDir = objects.directoryProperty()
    override val outputSiteDir = objects.directoryProperty()
    override val outputSchemaDir = objects.directoryProperty()
    override val defaultPackage = objects.property(String::class.java)
    override val generateEpisode = objects.property(Boolean::class.java)
    override val bindingFiles = objects.fileCollection()
    override val catalogFile = objects.fileProperty()
    override val modelsToDocument: Property<String> = objects.property(String::class.java)
    override val vodslDir: DirectoryProperty = objects.directoryProperty()
    override val vodslFiles = objects.fileCollection()



//    override val options = objects.listProperty(String::class.java)
//    override val markGenerated = objects.property(Boolean::class.java).convention(false)

   val groups: NamedDomainObjectContainer<VodmlExtensionGroup> = objects.domainObjectContainer(VodmlExtensionGroup::class.java)

        init {

            vodmlDir.set(layout.projectDirectory.dir("src/main/vo-dml"))
            outputJavaDir.set(layout.buildDirectory.dir("generated/sources/vodml/java/"))
            outputPythonDir.set(layout.buildDirectory.dir("generated/sources/vodml/python/"))
            outputDocDir.set(layout.buildDirectory.dir("generated/docs/vodml/"))
            outputSiteDir.set(layout.buildDirectory.dir("generated/docs/vodml-site/"))
            outputSchemaDir.set(layout.buildDirectory.dir("generated/sources/vodml/schema/"))
            defaultPackage.set("vodml.generated")
            generateEpisode.set(false)
            vodslDir.set(layout.projectDirectory.dir("src/main/vodsl"))

            groups.configureEach {
                vodmlDir.set(this@VodmlExtension.vodmlDir) // note that files not explicitly set
                outputJavaDir.set(layout.buildDirectory.dir("generated/sources/vodml-$name/java"))
                outputPythonDir.set(layout.buildDirectory.dir("generated/sources/vodml-$name/python"))
                outputSchemaDir.set(layout.buildDirectory.dir("generated/sources/vodml-$name/schema"))
                outputDocDir.set(layout.buildDirectory.dir("generated/docs/vodml-$name/"))
                outputSiteDir.set(layout.buildDirectory.dir("generated/docs/vodml-site-$name/"))
                defaultPackage.set(this@VodmlExtension.defaultPackage)
                generateEpisode.set(this@VodmlExtension.generateEpisode)
                catalogFile.set(this@VodmlExtension.catalogFile)
                modelsToDocument.set("")
                vodslDir.set(this@VodmlExtension.vodslDir)
            }
        }

}
