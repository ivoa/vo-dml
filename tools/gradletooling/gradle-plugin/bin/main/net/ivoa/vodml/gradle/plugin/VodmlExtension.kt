package net.ivoa.vodml.gradle.plugin

import org.gradle.api.NamedDomainObjectContainer
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.ProjectLayout
import org.gradle.api.model.ObjectFactory
import org.gradle.api.provider.ListProperty
import org.gradle.api.provider.Property
import javax.inject.Inject


/*
 * Created on 02/08/2021 by Paul Harrison (paul.harrison@manchester.ac.uk). 
 */

open class VodmlExtension @Inject constructor(objects: ObjectFactory, layout: ProjectLayout): VodmlExtensionGroup {
    override val name = "Defaults"
    override val vodmlDir = objects.directoryProperty().convention(layout.projectDirectory.dir("src/main/vo-dml"))
    override val vodmlFiles = objects.fileCollection()
    override val outputJavaDir = objects.directoryProperty().convention(layout.buildDirectory.dir("generated/sources/vodml/java/"))
    override val outputDocDir = objects.directoryProperty().convention(layout.buildDirectory.dir("generated/docs/vodml/"))
    override val outputResourcesDir = objects.directoryProperty().convention(layout.buildDirectory.dir("generated/sources/vodml/resources/"))
    override val defaultPackage = objects.property(String::class.java).convention("vodml.generated")
    override val generateEpisode = objects.property(Boolean::class.java).convention(false)
    override val bindingFiles = objects.fileCollection()
    override val catalogFile = objects.fileProperty().convention(layout.projectDirectory.file("catalog.xml"))
    override val modelsToDocument: Property<String> = objects.property(String::class.java)
    override val vodslDir: DirectoryProperty = objects.directoryProperty().convention(layout.projectDirectory.dir("src/main/vodsl"))
    override val vodslFiles = objects.fileCollection()



//    override val options = objects.listProperty(String::class.java)
//    override val markGenerated = objects.property(Boolean::class.java).convention(false)

   val groups: NamedDomainObjectContainer<VodmlExtensionGroup> = objects.domainObjectContainer(VodmlExtensionGroup::class.java)

        init {
            groups.configureEach {
                vodmlDir.convention(this@VodmlExtension.vodmlDir) // note that files not explicitly set
                outputJavaDir.convention(layout.buildDirectory.dir("generated/sources/vodml-$name/java"))
                outputResourcesDir.convention(layout.buildDirectory.dir("generated/sources/vodml-$name/resources"))
                outputDocDir.convention(layout.buildDirectory.dir("generated/docs/vodml-$name/"))
                defaultPackage.convention(this@VodmlExtension.defaultPackage)
                generateEpisode.convention(this@VodmlExtension.generateEpisode)
                catalogFile.convention(this@VodmlExtension.catalogFile)
                modelsToDocument.convention("")
                vodslDir.convention(this@VodmlExtension.vodslDir)
            }
        }

}
